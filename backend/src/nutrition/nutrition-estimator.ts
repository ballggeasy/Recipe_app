import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import sharp from 'sharp';
import { NutritionInfo } from '../recipes/recipe.entity';

/** What the model gets to look at: the photo plus the facts that decide portion size. */
export interface NutritionEstimateInput {
  name: string;
  servings: number;
  ingredients: string[];
  /** The recipe photo as stored (any size/format sharp can read); omitted when the recipe has none. */
  image?: Buffer;
}

export const DEFAULT_NUTRITION_MODEL = 'openai/gpt-6-luna';
const DEFAULT_AI_BASE_URL = 'https://ai.psu.blue/v1';
const REQUEST_TIMEOUT_MS = 90_000;
/**
 * The gateway counts an inline base64 image as text tokens (a 700 KB photo came to 545k tokens,
 * over every model's limit), so photos are shrunk to about 40 KB before sending.
 */
const IMAGE_MAX_SIDE = 512;

const SYSTEM_PROMPT = `You are a nutritionist. Estimate the nutrition of ONE serving of the dish.
Use the ingredient list and the number of servings as the main evidence for quantities; use the photo, when there is one, for portion size, cooking method (fried, oil, sauce) and anything the list leaves out.
Reply with JSON only, no markdown: {"calories": integer kcal, "protein": grams, "fat": grams, "carbs": grams, "sugar": grams, "sodium": milligrams}`;

/** Upper bounds for one serving; anything above is a broken reply, not food. */
const LIMITS: Record<keyof Omit<NutritionInfo, 'source'>, number> = {
  calories: 5000,
  protein: 500,
  fat: 500,
  carbs: 1000,
  sugar: 500,
  sodium: 20000,
};

/**
 * Estimates per-serving nutrition with a vision model behind an OpenAI-compatible gateway
 * (PSU dotBlue AI by default). Disabled, with every call failing as 503, until AI_API_KEY is set.
 */
@Injectable()
export class NutritionEstimator {
  private readonly logger = new Logger(NutritionEstimator.name);

  get isEnabled(): boolean {
    return Boolean(process.env.AI_API_KEY?.trim());
  }

  get model(): string {
    return process.env.NUTRITION_MODEL?.trim() || DEFAULT_NUTRITION_MODEL;
  }

  async estimate(input: NutritionEstimateInput): Promise<NutritionInfo> {
    if (!this.isEnabled) {
      throw new ServiceUnavailableException('ยังไม่ได้ตั้งค่า AI สำหรับประเมินโภชนาการ');
    }
    const content: unknown[] = [{ type: 'text', text: describeRecipe(input) }];
    if (input.image) {
      content.push({ type: 'image_url', image_url: { url: await toSmallJpegDataUrl(input.image) } });
    }

    const baseUrl = (process.env.AI_BASE_URL?.trim() || DEFAULT_AI_BASE_URL).replace(/\/+$/, '');
    let response: Response;
    try {
      response = await fetch(`${baseUrl}/chat/completions`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${process.env.AI_API_KEY!.trim()}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: this.model,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user', content },
          ],
          temperature: 0,
          stream: false,
        }),
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
    } catch (error) {
      this.logger.warn(`AI request failed: ${error instanceof Error ? error.message : String(error)}`);
      throw new ServiceUnavailableException('ติดต่อ AI ไม่ได้ กรุณาลองใหม่ภายหลัง');
    }

    const body = await response.text();
    if (!response.ok) {
      // The body can echo request details; log only its start, never the API key (it is not in the body).
      this.logger.warn(`AI gateway answered ${response.status}: ${body.slice(0, 200)}`);
      throw new ServiceUnavailableException('AI ประเมินโภชนาการไม่สำเร็จ กรุณาลองใหม่ภายหลัง');
    }
    const nutrition = parseNutritionReply(readCompletionText(body));
    if (!nutrition) {
      this.logger.warn(`AI reply had no usable nutrition JSON: ${body.slice(0, 200)}`);
      throw new ServiceUnavailableException('AI ตอบกลับในรูปแบบที่อ่านไม่ได้ กรุณาลองใหม่');
    }
    return nutrition;
  }
}

function describeRecipe({ name, servings, ingredients }: NutritionEstimateInput): string {
  return [
    `Dish: ${name}`,
    `Servings the recipe makes: ${servings}`,
    'Ingredients (whole recipe):',
    ...(ingredients.length ? ingredients.map((i) => `- ${i}`) : ['- (not listed)']),
  ].join('\n');
}

async function toSmallJpegDataUrl(image: Buffer): Promise<string> {
  const jpeg = await sharp(image)
    .rotate() // honour EXIF orientation from phone cameras
    .resize(IMAGE_MAX_SIDE, IMAGE_MAX_SIDE, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 80 })
    .toBuffer();
  return `data:image/jpeg;base64,${jpeg.toString('base64')}`;
}

/**
 * The assistant text of a chat completion. The PSU gateway sometimes answers as a server-sent
 * event stream even when `stream: false` was asked for, so both shapes are accepted.
 */
export function readCompletionText(body: string): string {
  if (body.trimStart().startsWith('data:')) {
    let text = '';
    for (const raw of body.split('\n')) {
      const line = raw.trim();
      if (!line.startsWith('data:') || line === 'data: [DONE]') continue;
      try {
        const chunk = JSON.parse(line.slice('data:'.length));
        text += chunk.choices?.[0]?.delta?.content ?? chunk.choices?.[0]?.message?.content ?? '';
      } catch {
        // keep-alive or partial line: skip it
      }
    }
    return text;
  }
  try {
    const json = JSON.parse(body);
    const content = json.choices?.[0]?.message?.content;
    return typeof content === 'string' ? content : '';
  } catch {
    return '';
  }
}

/**
 * Pulls the nutrition object out of the model's reply (tolerating code fences or a sentence
 * around it) and returns it rounded, or null when a value is missing, negative or absurd.
 */
export function parseNutritionReply(text: string): NutritionInfo | null {
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) return null;
  let raw: Record<string, unknown>;
  try {
    raw = JSON.parse(match[0]);
  } catch {
    return null;
  }
  const values = {} as Record<keyof typeof LIMITS, number>;
  for (const [key, max] of Object.entries(LIMITS) as [keyof typeof LIMITS, number][]) {
    const value = Number(raw[key]);
    if (!Number.isFinite(value) || value < 0 || value > max) return null;
    values[key] = key === 'calories' || key === 'sodium' ? Math.round(value) : Math.round(value * 10) / 10;
  }
  return { ...values, source: 'ai' };
}
