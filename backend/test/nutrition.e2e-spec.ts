import { INestApplication } from '@nestjs/common';
import { rmSync } from 'fs';
import sharp from 'sharp';
import request from 'supertest';
import { uploadsRoot } from '../src/common/image-upload';
import { NutritionEstimateInput, NutritionEstimator } from '../src/nutrition/nutrition-estimator';
import { NutritionInfo } from '../src/recipes/recipe.entity';
import { RecipesService } from '../src/recipes/recipes.service';
import { createTestApp } from './helpers/create-test-app';

const newRecipe = {
  name: 'ไก่ทอดหาดใหญ่',
  emoji: '🍗',
  category: 'อาหารจานเดียว',
  country: 'ไทย',
  cookTimeMinutes: 30,
  difficulty: 'ง่าย',
  servings: 2,
  ingredients: ['ไก่ 1 กิโลกรัม', 'หอมเจียว'],
  steps: ['หมัก', 'ทอด'],
};

/** Stand-in for the AI: answers instantly (or holds the next answer back) and records what it was shown. */
class FakeEstimator {
  isEnabled = true;
  calls: NutritionEstimateInput[] = [];
  private nextGate: Promise<void> | null = null;
  private release = () => {};

  holdNextAnswer() {
    this.nextGate = new Promise((resolve) => (this.release = resolve));
  }

  releaseHeldAnswer() {
    this.release();
  }

  async estimate(input: NutritionEstimateInput): Promise<NutritionInfo> {
    this.calls.push(input);
    const gate = this.nextGate;
    this.nextGate = null;
    if (gate) await gate;
    return { calories: 100 * input.servings, protein: 30, fat: 20, carbs: 40, sugar: 2, sodium: 800, source: 'ai' };
  }
}

describe('AI nutrition estimates (e2e)', () => {
  let app: INestApplication;
  let fake: FakeEstimator;
  let recipes: RecipesService;

  beforeAll(async () => {
    fake = new FakeEstimator();
    app = await createTestApp((builder) => builder.overrideProvider(NutritionEstimator).useValue(fake));
    recipes = app.get(RecipesService);
  });

  beforeEach(() => {
    fake.calls = [];
    fake.isEnabled = true;
  });

  afterAll(async () => {
    await app.close();
    rmSync(uploadsRoot(), { recursive: true, force: true });
  });

  const http = () => request(app.getHttpServer());
  const bearer = (token: string) => ({ Authorization: `Bearer ${token}` });
  let userCount = 0;

  async function registerUser(): Promise<string> {
    userCount += 1;
    const res = await http()
      .post('/auth/register')
      .send({ name: 'Cook', email: `nutrition-${userCount}@example.com`, password: 'secret123' })
      .expect(201);
    return res.body.accessToken;
  }

  async function nutritionOf(id: string) {
    await recipes.settleEstimates();
    return (await http().get(`/recipes/${id}`).expect(200)).body.nutrition;
  }

  it('estimates a new recipe in the background and stores it as AI values', async () => {
    const token = await registerUser();
    const created = await http().post('/recipes').set(bearer(token)).send(newRecipe).expect(201);

    expect(await nutritionOf(created.body.id)).toEqual({
      calories: 200,
      protein: 30,
      fat: 20,
      carbs: 40,
      sugar: 2,
      sodium: 800,
      source: 'ai',
    });
    expect(fake.calls[0]).toMatchObject({ name: 'ไก่ทอดหาดใหญ่', servings: 2, ingredients: newRecipe.ingredients });
  });

  it('keeps nutrition the cook typed in', async () => {
    const token = await registerUser();
    const nutrition = { calories: 450, protein: 20, fat: 10, carbs: 60, sugar: 5, sodium: 600 };
    const created = await http()
      .post('/recipes')
      .set(bearer(token))
      .send({ ...newRecipe, nutrition })
      .expect(201);

    expect(await nutritionOf(created.body.id)).toEqual(nutrition);
    expect(fake.calls).toHaveLength(0);
  });

  it('re-estimates when servings or ingredients change, but not for other edits', async () => {
    const token = await registerUser();
    const { id } = (await http().post('/recipes').set(bearer(token)).send(newRecipe).expect(201)).body;
    await recipes.settleEstimates();
    fake.calls = [];

    const current = (await http().get(`/recipes/${id}`).expect(200)).body;
    // The app sends the AI values back unchanged when it saves the form.
    await http()
      .patch(`/recipes/${id}`)
      .set(bearer(token))
      .send({ tips: 'ทอดไฟกลาง', nutrition: current.nutrition })
      .expect(200);
    await recipes.settleEstimates();
    expect(fake.calls).toHaveLength(0);

    await http().patch(`/recipes/${id}`).set(bearer(token)).send({ servings: 4 }).expect(200);
    expect((await nutritionOf(id)).calories).toBe(400);
    expect(fake.calls).toHaveLength(1);
  });

  it('estimates again from the photo once one is uploaded', async () => {
    const token = await registerUser();
    const { id } = (await http().post('/recipes').set(bearer(token)).send(newRecipe).expect(201)).body;
    await recipes.settleEstimates();
    fake.calls = [];

    const photo = await sharp({ create: { width: 40, height: 30, channels: 3, background: '#a52' } })
      .jpeg()
      .toBuffer();
    await http()
      .post(`/recipes/${id}/image`)
      .set(bearer(token))
      .attach('file', photo, { filename: 'chicken.jpg', contentType: 'image/jpeg' })
      .expect(201);
    await recipes.settleEstimates();

    expect(fake.calls).toHaveLength(1);
    expect(fake.calls[0].image?.equals(photo)).toBe(true);
  });

  it('drops an estimate whose recipe changed while the AI was answering', async () => {
    const token = await registerUser();
    fake.holdNextAnswer();
    const { id } = (await http().post('/recipes').set(bearer(token)).send(newRecipe).expect(201)).body;
    // Edited while the first estimate is still waiting on the AI; the edit's own estimate lands first.
    await http().patch(`/recipes/${id}`).set(bearer(token)).send({ servings: 3 }).expect(200);
    await new Promise((resolve) => setTimeout(resolve, 50));
    expect((await http().get(`/recipes/${id}`).expect(200)).body.nutrition.calories).toBe(300);
    fake.releaseHeldAnswer();

    expect((await nutritionOf(id)).calories).toBe(300);
    expect(fake.calls.map((c) => c.servings)).toEqual([2, 3]);
  });

  describe('POST /recipes/:id/nutrition/estimate', () => {
    it("re-estimates on the owner's request, replacing hand-entered values", async () => {
      const token = await registerUser();
      const nutrition = { calories: 1, protein: 1, fat: 1, carbs: 1, sugar: 1, sodium: 1 };
      const { id } = (
        await http()
          .post('/recipes')
          .set(bearer(token))
          .send({ ...newRecipe, nutrition })
          .expect(201)
      ).body;

      const res = await http().post(`/recipes/${id}/nutrition/estimate`).set(bearer(token)).expect(201);

      expect(res.body.nutrition).toMatchObject({ calories: 200, source: 'ai' });
    });

    it('is only for the owner, and needs a login', async () => {
      const owner = await registerUser();
      const other = await registerUser();
      const { id } = (await http().post('/recipes').set(bearer(owner)).send(newRecipe).expect(201)).body;
      const sample = (await http().get('/recipes').expect(200)).body.find((r: { isOfficial: boolean }) => r.isOfficial);

      await http().post(`/recipes/${id}/nutrition/estimate`).expect(401);
      await http().post(`/recipes/${id}/nutrition/estimate`).set(bearer(other)).expect(403);
      await http().post(`/recipes/${sample.id}/nutrition/estimate`).set(bearer(owner)).expect(403);
      await http().post('/recipes/no-such-recipe/nutrition/estimate').set(bearer(owner)).expect(404);
    });
  });

  it('skips the background estimate when AI is not configured', async () => {
    fake.isEnabled = false;
    const token = await registerUser();
    const { id } = (await http().post('/recipes').set(bearer(token)).send(newRecipe).expect(201)).body;

    expect(await nutritionOf(id)).toBeNull();
    expect(fake.calls).toHaveLength(0);
  });
});

describe('AI nutrition estimate without a key (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('answers 503 instead of calling out', async () => {
    const http = () => request(app.getHttpServer());
    const reg = await http()
      .post('/auth/register')
      .send({ name: 'Cook', email: 'nutrition-nokey@example.com', password: 'secret123' })
      .expect(201);
    const auth = { Authorization: `Bearer ${reg.body.accessToken}` };
    const { id } = (await http().post('/recipes').set(auth).send(newRecipe).expect(201)).body;

    const res = await http().post(`/recipes/${id}/nutrition/estimate`).set(auth).expect(503);
    expect(res.body.message).toBe('ยังไม่ได้ตั้งค่า AI สำหรับประเมินโภชนาการ');
  });
});
