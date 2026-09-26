import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { recipeSeeds } from '../src/seed/seed-data';

const newRecipe = {
  name: 'Test Krapao',
  emoji: '🌶️',
  category: 'อาหารจานเดียว',
  country: 'ไทย',
  cookTimeMinutes: 15,
  difficulty: 'ง่าย',
  ingredients: ['หมูสับ', 'ใบกะเพรา'],
  steps: ['ผัดหมู', 'ใส่กะเพรา'],
};

describe('Recipe API (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    // Same pipe configuration as src/main.ts
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  const http = () => request(app.getHttpServer());

  async function registerUser(email: string): Promise<{ token: string; id: string }> {
    const res = await http()
      .post('/auth/register')
      .send({ name: 'Tester', email, password: 'secret123' })
      .expect(201);
    return { token: res.body.accessToken, id: res.body.user.id };
  }

  describe('auth', () => {
    it('registers, logs in and returns the current user', async () => {
      const { id } = await registerUser('alice@example.com');

      const login = await http()
        .post('/auth/login')
        .send({ email: 'ALICE@example.com', password: 'secret123' })
        .expect(201);
      expect(login.body.user).toEqual({
        id,
        email: 'alice@example.com',
        name: 'Tester',
        profileImageUrl: null,
      });

      const me = await http()
        .get('/auth/me')
        .set('Authorization', `Bearer ${login.body.accessToken}`)
        .expect(200);
      expect(me.body.id).toBe(id);
      expect(me.body).not.toHaveProperty('passwordHash');
    });

    it('rejects a duplicate email with 409', async () => {
      await registerUser('dup@example.com');
      await http()
        .post('/auth/register')
        .send({ name: 'Other', email: 'dup@example.com', password: 'secret123' })
        .expect(409);
    });

    it('rejects a wrong password with 401', async () => {
      await registerUser('bob@example.com');
      await http().post('/auth/login').send({ email: 'bob@example.com', password: 'nope-nope' }).expect(401);
    });

    it('rejects invalid bodies and unknown fields with 400', async () => {
      await http().post('/auth/register').send({ name: 'X', email: 'not-an-email', password: 'secret123' }).expect(400);
      await http().post('/auth/register').send({ name: 'X', email: 'x@example.com', password: '123' }).expect(400);
      await http()
        .post('/auth/register')
        .send({ name: 'X', email: 'x2@example.com', password: 'secret123', isAdmin: true })
        .expect(400);
    });

    it('requires a valid token for protected routes', async () => {
      await http().get('/auth/me').expect(401);
      await http().get('/auth/me').set('Authorization', 'Bearer not-a-real-token').expect(401);
    });

    it('invalidates the token after the account is deleted', async () => {
      const { token } = await registerUser('gone@example.com');
      await http().delete('/auth/account').set('Authorization', `Bearer ${token}`).expect(200);
      await http().get('/auth/me').set('Authorization', `Bearer ${token}`).expect(401);
    });
  });

  describe('recipes', () => {
    it('serves the seeded catalog without authentication', async () => {
      const res = await http().get('/recipes').expect(200);
      expect(res.body).toHaveLength(recipeSeeds.length);
    });

    it('lets a user create, edit and delete their own recipe', async () => {
      const { token, id } = await registerUser('cook@example.com');
      const auth = { Authorization: `Bearer ${token}` };

      const created = await http().post('/recipes').set(auth).send(newRecipe).expect(201);
      expect(created.body).toMatchObject({ name: 'Test Krapao', uploaderId: id, isOfficial: false });
      const recipeId = created.body.id;

      const patched = await http().patch(`/recipes/${recipeId}`).set(auth).send({ name: 'Renamed' }).expect(200);
      expect(patched.body.name).toBe('Renamed');

      await http().delete(`/recipes/${recipeId}`).set(auth).expect(200);
      await http().get(`/recipes/${recipeId}`).expect(404);
    });

    it("forbids editing or deleting someone else's recipe", async () => {
      const owner = await registerUser('owner@example.com');
      const other = await registerUser('other@example.com');

      const created = await http()
        .post('/recipes')
        .set('Authorization', `Bearer ${owner.token}`)
        .send(newRecipe)
        .expect(201);

      await http()
        .patch(`/recipes/${created.body.id}`)
        .set('Authorization', `Bearer ${other.token}`)
        .send({ name: 'Hacked' })
        .expect(403);
      await http()
        .delete(`/recipes/${created.body.id}`)
        .set('Authorization', `Bearer ${other.token}`)
        .expect(403);
    });

    it('requires a token to create a recipe', async () => {
      await http().post('/recipes').send(newRecipe).expect(401);
    });

    it('rejects a recipe missing required fields with 400', async () => {
      const { token } = await registerUser('lazy@example.com');
      await http()
        .post('/recipes')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'No steps' })
        .expect(400);
    });
  });
});
