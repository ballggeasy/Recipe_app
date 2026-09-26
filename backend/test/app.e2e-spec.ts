import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { existsSync, readdirSync, rmSync, writeFileSync } from 'fs';
import { basename, join } from 'path';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { uploadsRoot } from '../src/common/image-upload';
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
    rmSync(uploadsRoot(), { recursive: true, force: true });
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

  describe('recipe images', () => {
    // Multer only checks the declared MIME type, so any bytes work as a stand-in image.
    const png = Buffer.from('fake-png-bytes');
    const uploadedFiles = () => {
      const dir = join(uploadsRoot(), 'recipes');
      return existsSync(dir) ? readdirSync(dir) : [];
    };
    const fileOnDisk = (url: string) => join(uploadsRoot(), url.replace(/^\/uploads\//, ''));

    async function createRecipe(token: string): Promise<string> {
      const res = await http().post('/recipes').set('Authorization', `Bearer ${token}`).send(newRecipe).expect(201);
      return res.body.id;
    }

    function upload(recipeId: string, token: string, contentType = 'image/png', filename = 'dish.png') {
      return http()
        .post(`/recipes/${recipeId}/image`)
        .set('Authorization', `Bearer ${token}`)
        .attach('file', png, { filename, contentType });
    }

    it('stores the image, links it to the recipe and replaces the previous one', async () => {
      const { token } = await registerUser('photo@example.com');
      const recipeId = await createRecipe(token);

      const first = await upload(recipeId, token).expect(201);
      expect(first.body.imageUrl).toMatch(new RegExp(`^/uploads/recipes/${recipeId}-\\d+\\.png$`));
      expect(first.body.imageUrls).toEqual([first.body.imageUrl]);
      expect(existsSync(fileOnDisk(first.body.imageUrl))).toBe(true);

      const fetched = await http().get(`/recipes/${recipeId}`).expect(200);
      expect(fetched.body.imageUrl).toBe(first.body.imageUrl);

      // Timestamps are part of the filename; make sure the second upload gets a new name.
      await new Promise((r) => setTimeout(r, 5));
      const second = await upload(recipeId, token, 'image/jpeg', 'dish.jpg').expect(201);
      expect(second.body.imageUrl).toMatch(/\.jpg$/);
      await waitFor(() => !existsSync(fileOnDisk(first.body.imageUrl)));
      expect(existsSync(fileOnDisk(second.body.imageUrl))).toBe(true);
    });

    it('uses the MIME type for the extension, never the client filename', async () => {
      const { token } = await registerUser('sneaky@example.com');
      const recipeId = await createRecipe(token);

      const res = await upload(recipeId, token, 'image/png', 'evil.html').expect(201);
      expect(res.body.imageUrl).toMatch(/\.png$/);
    });

    it('rejects non-image and SVG files with 400', async () => {
      const { token } = await registerUser('svg@example.com');
      const recipeId = await createRecipe(token);

      await upload(recipeId, token, 'text/plain', 'notes.txt').expect(400);
      await upload(recipeId, token, 'image/svg+xml', 'logo.svg').expect(400);
    });

    it("forbids uploading to someone else's recipe and leaves no file behind", async () => {
      const owner = await registerUser('img-owner@example.com');
      const other = await registerUser('img-other@example.com');
      const recipeId = await createRecipe(owner.token);
      const before = uploadedFiles().length;

      await upload(recipeId, other.token).expect(403);
      await upload('does-not-exist', other.token).expect(404);

      expect(uploadedFiles()).toHaveLength(before);
    });

    it('requires a token', async () => {
      await http().post('/recipes/whatever/image').attach('file', png, { filename: 'a.png', contentType: 'image/png' }).expect(401);
    });

    it('deletes the image file when the recipe is deleted', async () => {
      const { token } = await registerUser('cleanup@example.com');
      const recipeId = await createRecipe(token);
      const { body } = await upload(recipeId, token).expect(201);

      await http().delete(`/recipes/${recipeId}`).set('Authorization', `Bearer ${token}`).expect(200);

      await waitFor(() => !existsSync(fileOnDisk(body.imageUrl)));
    });
  });

  describe('avatar cleanup', () => {
    it('never deletes files outside the uploads folder, even if profileImageUrl points there', async () => {
      const outside = join(uploadsRoot(), '..', `keep-me-${Date.now()}.txt`);
      writeFileSync(outside, 'important');
      const { token } = await registerUser('traversal@example.com');

      await http()
        .patch('/auth/profile')
        .set('Authorization', `Bearer ${token}`)
        .send({ profileImageUrl: `/uploads/../${basename(outside)}` })
        .expect(200);
      await http()
        .post('/auth/avatar')
        .set('Authorization', `Bearer ${token}`)
        .attach('file', Buffer.from('x'), { filename: 'me.png', contentType: 'image/png' })
        .expect(201);

      await new Promise((r) => setTimeout(r, 50));
      expect(existsSync(outside)).toBe(true);
      rmSync(outside);
    });
  });
});

async function waitFor(condition: () => boolean, timeoutMs = 1000): Promise<void> {
  const start = Date.now();
  while (!condition()) {
    if (Date.now() - start > timeoutMs) throw new Error('condition not met in time');
    await new Promise((r) => setTimeout(r, 10));
  }
}
