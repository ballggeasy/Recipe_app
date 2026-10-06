import { ServiceUnavailableException } from '@nestjs/common';
import sharp from 'sharp';
import {
  DEFAULT_NUTRITION_MODEL,
  NutritionEstimator,
  parseNutritionReply,
  readCompletionText,
} from '../src/nutrition/nutrition-estimator';

const reply = { calories: 702.4, protein: 29.04, fat: 42, carbs: 52, sugar: 3, sodium: 750.6 };

function completion(content: string) {
  return JSON.stringify({ choices: [{ message: { role: 'assistant', content } }] });
}

describe('readCompletionText', () => {
  it('reads a regular chat completion', () => {
    expect(readCompletionText(completion('hello'))).toBe('hello');
  });

  it('joins the deltas when the gateway streams despite stream: false', () => {
    const sse = [
      'data: {"choices":[{"delta":{"content":"{\\"calories\\":"}}]}',
      '',
      ': keep-alive',
      'data: {"choices":[{"delta":{"content":"500}"}}]}',
      'data: [DONE]',
    ].join('\n');
    expect(readCompletionText(sse)).toBe('{"calories":500}');
  });

  it('returns an empty string for a body that is not a completion', () => {
    expect(readCompletionText('<html>Bad Gateway</html>')).toBe('');
  });
});

describe('parseNutritionReply', () => {
  it('takes the JSON out of a fenced or chatty reply and rounds it', () => {
    expect(parseNutritionReply(`Sure!\n\`\`\`json\n${JSON.stringify(reply)}\n\`\`\``)).toEqual({
      calories: 702,
      protein: 29,
      fat: 42,
      carbs: 52,
      sugar: 3,
      sodium: 751,
      source: 'ai',
    });
  });

  it('accepts numbers sent as strings', () => {
    expect(parseNutritionReply(JSON.stringify({ ...reply, protein: '12.34' }))?.protein).toBe(12.3);
  });

  it.each([
    ['a missing value', { ...reply, sodium: undefined }],
    ['a negative value', { ...reply, fat: -1 }],
    ['an absurd value', { ...reply, calories: 90000 }],
    ['a non-number', { ...reply, carbs: 'a lot' }],
  ])('rejects %s', (_label, value) => {
    expect(parseNutritionReply(JSON.stringify(value))).toBeNull();
  });

  it('rejects a reply without JSON', () => {
    expect(parseNutritionReply('I cannot tell from this photo.')).toBeNull();
  });
});

describe('NutritionEstimator', () => {
  const realFetch = global.fetch;
  const env = { ...process.env };
  let fetchMock: jest.Mock;

  beforeEach(() => {
    process.env.AI_API_KEY = 'test-key';
    delete process.env.AI_BASE_URL;
    delete process.env.NUTRITION_MODEL;
    fetchMock = jest.fn(async () => new Response(completion(JSON.stringify(reply)), { status: 200 }));
    global.fetch = fetchMock as unknown as typeof fetch;
  });

  afterEach(() => {
    global.fetch = realFetch;
    process.env = { ...env };
  });

  const input = { name: 'ผัดกะเพรา', servings: 2, ingredients: ['หมูสับ 250 กรัม', 'ข้าวสวย 2 จาน'] };
  const sentBody = () => JSON.parse(fetchMock.mock.calls[0][1].body);

  it('is disabled without an API key and then fails as 503 without calling out', async () => {
    process.env.AI_API_KEY = ' ';
    const estimator = new NutritionEstimator();

    expect(estimator.isEnabled).toBe(false);
    await expect(estimator.estimate(input)).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('asks the configured gateway and model, with the recipe facts, and returns AI-tagged values', async () => {
    process.env.AI_BASE_URL = 'https://gateway.example/v1/';
    process.env.NUTRITION_MODEL = 'some/model';

    const nutrition = await new NutritionEstimator().estimate(input);

    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://gateway.example/v1/chat/completions');
    expect(init.headers.Authorization).toBe('Bearer test-key');
    const body = sentBody();
    expect(body.model).toBe('some/model');
    expect(body.messages[1].content).toEqual([
      { type: 'text', text: expect.stringContaining('Servings the recipe makes: 2') },
    ]);
    expect(body.messages[1].content[0].text).toContain('- หมูสับ 250 กรัม');
    expect(nutrition).toMatchObject({ calories: 702, source: 'ai' });
  });

  it('defaults to the PSU gateway and the model chosen by comparison', async () => {
    await new NutritionEstimator().estimate(input);
    expect(fetchMock.mock.calls[0][0]).toBe('https://ai.psu.blue/v1/chat/completions');
    expect(sentBody().model).toBe(DEFAULT_NUTRITION_MODEL);
  });

  it('sends the photo shrunk to a small JPEG, since the gateway counts base64 as text', async () => {
    const photo = await sharp({ create: { width: 3000, height: 2000, channels: 3, background: '#c33' } })
      .png()
      .toBuffer();

    await new NutritionEstimator().estimate({ ...input, image: photo });

    const url: string = sentBody().messages[1].content[1].image_url.url;
    expect(url.startsWith('data:image/jpeg;base64,')).toBe(true);
    const sent = Buffer.from(url.slice('data:image/jpeg;base64,'.length), 'base64');
    const meta = await sharp(sent).metadata();
    expect(Math.max(meta.width!, meta.height!)).toBe(512);
    expect(sent.length).toBeLessThan(60_000);
  });

  it('turns a gateway error, a network failure and an unreadable reply into 503', async () => {
    const estimator = new NutritionEstimator();

    fetchMock.mockResolvedValueOnce(new Response('{"error":"Provider returned error"}', { status: 400 }));
    await expect(estimator.estimate(input)).rejects.toBeInstanceOf(ServiceUnavailableException);

    fetchMock.mockRejectedValueOnce(new TypeError('fetch failed'));
    await expect(estimator.estimate(input)).rejects.toBeInstanceOf(ServiceUnavailableException);

    fetchMock.mockResolvedValueOnce(new Response(completion('Looks tasty!'), { status: 200 }));
    await expect(estimator.estimate(input)).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
