import { INestApplication } from '@nestjs/common';
import { rmSync } from 'fs';
import request from 'supertest';
import { uploadsRoot } from '../src/common/image-upload';
import { createTestApp } from './helpers/create-test-app';

const newRecipe = {
  name: 'Community Test Dish',
  emoji: '🍲',
  category: 'อาหารจานเดียว',
  country: 'ไทย',
  cookTimeMinutes: 10,
  difficulty: 'ง่าย',
  ingredients: ['ข้าว'],
  steps: ['หุง'],
};

describe('Favorites, reviews, comments, meal plan and profile (e2e)', () => {
  let app: INestApplication;
  let seedRecipeId: string;

  beforeAll(async () => {
    app = await createTestApp();
    seedRecipeId = (await request(app.getHttpServer()).get('/recipes').expect(200)).body[0].id;
  });

  afterAll(async () => {
    await app.close();
    rmSync(uploadsRoot(), { recursive: true, force: true });
  });

  const http = () => request(app.getHttpServer());
  const bearer = (token: string) => ({ Authorization: `Bearer ${token}` });

  async function registerUser(email: string, password = 'secret123'): Promise<{ token: string; id: string }> {
    const res = await http().post('/auth/register').send({ name: 'Tester', email, password }).expect(201);
    return { token: res.body.accessToken, id: res.body.user.id };
  }

  async function createRecipe(token: string): Promise<string> {
    return (await http().post('/recipes').set(bearer(token)).send(newRecipe).expect(201)).body.id;
  }

  describe('favorites and folders', () => {
    it('requires a token', async () => {
      await http().get('/favorites').expect(401);
      await http().get('/folders').expect(401);
      await http().post(`/favorites/${seedRecipeId}`).expect(401);
    });

    it('adds (idempotently), lists and removes favorites per user', async () => {
      const alice = await registerUser('fav-alice@example.com');
      const bob = await registerUser('fav-bob@example.com');

      await http().post(`/favorites/${seedRecipeId}`).set(bearer(alice.token)).expect(200);
      await http().post(`/favorites/${seedRecipeId}`).set(bearer(alice.token)).expect(200);

      expect((await http().get('/favorites').set(bearer(alice.token)).expect(200)).body).toEqual([seedRecipeId]);
      expect((await http().get('/favorites').set(bearer(bob.token)).expect(200)).body).toEqual([]);

      await http().delete(`/favorites/${seedRecipeId}`).set(bearer(alice.token)).expect(200);
      expect((await http().get('/favorites').set(bearer(alice.token)).expect(200)).body).toEqual([]);
    });

    it('refuses to favorite a recipe that does not exist', async () => {
      const { token } = await registerUser('fav-ghost@example.com');
      await http().post('/favorites/no-such-recipe').set(bearer(token)).expect(404);
    });

    it('manages folders and keeps them private to their owner', async () => {
      const owner = await registerUser('folder-owner@example.com');
      const other = await registerUser('folder-other@example.com');

      const folder = await http().post('/folders').set(bearer(owner.token)).send({ name: 'Dinner' }).expect(201);
      expect(folder.body).toMatchObject({ name: 'Dinner', userId: owner.id, recipeIds: [] });

      const added = await http()
        .post(`/folders/${folder.body.id}/recipes/${seedRecipeId}`)
        .set(bearer(owner.token))
        .expect(201);
      expect(added.body.recipeIds).toEqual([seedRecipeId]);

      await http().post(`/folders/${folder.body.id}/recipes/no-such-recipe`).set(bearer(owner.token)).expect(404);

      // Someone else's folder looks like it does not exist: no reading, changing or deleting it.
      expect((await http().get('/folders').set(bearer(other.token)).expect(200)).body).toEqual([]);
      await http().post(`/folders/${folder.body.id}/recipes/${seedRecipeId}`).set(bearer(other.token)).expect(404);
      await http().delete(`/folders/${folder.body.id}`).set(bearer(other.token)).expect(404);

      const removed = await http()
        .delete(`/folders/${folder.body.id}/recipes/${seedRecipeId}`)
        .set(bearer(owner.token))
        .expect(200);
      expect(removed.body.recipeIds).toEqual([]);

      await http().delete(`/folders/${folder.body.id}`).set(bearer(owner.token)).expect(200);
      expect((await http().get('/folders').set(bearer(owner.token)).expect(200)).body).toEqual([]);
    });
  });

  describe('reviews', () => {
    it('requires a token and a valid body', async () => {
      await http().post(`/recipes/${seedRecipeId}/reviews`).send({ rating: 5, content: 'x' }).expect(401);

      const { token } = await registerUser('review-invalid@example.com');
      await http()
        .post(`/recipes/${seedRecipeId}/reviews`)
        .set(bearer(token))
        .send({ rating: 9, content: 'too high' })
        .expect(400);
    });

    it('rejects a review for a recipe that does not exist', async () => {
      const { token } = await registerUser('review-ghost@example.com');
      await http()
        .post('/recipes/no-such-recipe/reviews')
        .set(bearer(token))
        .send({ rating: 4, content: 'ghost' })
        .expect(404);
    });

    it("keeps the recipe's average rating and review count in step with its reviews", async () => {
      const cook = await registerUser('review-cook@example.com');
      const fan1 = await registerUser('review-fan1@example.com');
      const fan2 = await registerUser('review-fan2@example.com');
      const recipeId = await createRecipe(cook.token);

      await http()
        .post(`/recipes/${recipeId}/reviews`)
        .set(bearer(fan1.token))
        .send({ rating: 5, content: 'great' })
        .expect(201);
      await http()
        .post(`/recipes/${recipeId}/reviews`)
        .set(bearer(fan2.token))
        .send({ rating: 3, content: 'ok' })
        .expect(201);

      const recipe = await http().get(`/recipes/${recipeId}`).expect(200);
      expect(recipe.body.reviewCount).toBe(2);
      expect(recipe.body.rating).toBeCloseTo(4);

      const list = await http().get(`/recipes/${recipeId}/reviews`).expect(200);
      expect(list.body).toHaveLength(2);
      expect(list.body[0]).toMatchObject({ content: 'ok', userId: fan2.id }); // newest first
    });

    it('toggles a like, adds a reply and flags a review', async () => {
      const cook = await registerUser('review-social-cook@example.com');
      const fan = await registerUser('review-social-fan@example.com');
      const recipeId = await createRecipe(cook.token);
      const review = (
        await http()
          .post(`/recipes/${recipeId}/reviews`)
          .set(bearer(fan.token))
          .send({ rating: 4, content: 'nice' })
          .expect(201)
      ).body;

      const liked = await http().post(`/reviews/${review.id}/like`).set(bearer(cook.token)).expect(201);
      expect(liked.body.likedByUserIds).toEqual([cook.id]);
      const unliked = await http().post(`/reviews/${review.id}/like`).set(bearer(cook.token)).expect(201);
      expect(unliked.body.likedByUserIds).toEqual([]);

      const replied = await http()
        .post(`/reviews/${review.id}/replies`)
        .set(bearer(cook.token))
        .send({ content: 'thanks!' })
        .expect(201);
      expect(replied.body.replies).toHaveLength(1);
      expect(replied.body.replies[0]).toMatchObject({ content: 'thanks!', userId: cook.id });

      const reported = await http().post(`/reviews/${review.id}/report`).set(bearer(cook.token)).expect(201);
      expect(reported.body.isReported).toBe(true);

      await http().post('/reviews/no-such-review/like').set(bearer(cook.token)).expect(404);
      await http().post(`/reviews/${review.id}/like`).expect(401);
    });

    it('lets only the author delete a review and refreshes the recipe rating', async () => {
      const cook = await registerUser('review-delete-cook@example.com');
      const fan = await registerUser('review-delete-fan@example.com');
      const other = await registerUser('review-delete-other@example.com');
      const recipeId = await createRecipe(cook.token);
      const review = (
        await http()
          .post(`/recipes/${recipeId}/reviews`)
          .set(bearer(fan.token))
          .send({ rating: 2, content: 'mine' })
          .expect(201)
      ).body;

      await http().delete(`/reviews/${review.id}`).set(bearer(other.token)).expect(403);
      await http().delete(`/reviews/${review.id}`).expect(401);
      await http().delete(`/reviews/${review.id}`).set(bearer(fan.token)).expect(200);

      const list = await http().get(`/recipes/${recipeId}/reviews`).expect(200);
      expect(list.body).toEqual([]);
      const recipe = await http().get(`/recipes/${recipeId}`).expect(200);
      expect(recipe.body.reviewCount).toBe(0);
      expect(recipe.body.rating).toBe(0);
    });

    it('lets only the author attach a photo to a review or a comment', async () => {
      const author = await registerUser('photo-author@example.com');
      const other = await registerUser('photo-other@example.com');
      const recipeId = await createRecipe(author.token);
      const png = Buffer.from('fake-png-bytes');
      const review = (
        await http()
          .post(`/recipes/${recipeId}/reviews`)
          .set(bearer(author.token))
          .send({ rating: 5, content: 'with photo' })
          .expect(201)
      ).body;
      const comment = (
        await http()
          .post(`/recipes/${recipeId}/comments`)
          .set(bearer(author.token))
          .send({ content: 'with photo' })
          .expect(201)
      ).body;

      await http()
        .post(`/reviews/${review.id}/image`)
        .set(bearer(other.token))
        .attach('file', png, { filename: 'a.png', contentType: 'image/png' })
        .expect(403);
      const withPhoto = await http()
        .post(`/reviews/${review.id}/image`)
        .set(bearer(author.token))
        .attach('file', png, { filename: 'a.png', contentType: 'image/png' })
        .expect(201);
      expect(withPhoto.body.imageUrls[0]).toMatch(/^\/uploads\/reviews\//);

      await http()
        .post(`/comments/${comment.id}/image`)
        .set(bearer(other.token))
        .attach('file', png, { filename: 'a.png', contentType: 'image/png' })
        .expect(403);
      const commentPhoto = await http()
        .post(`/comments/${comment.id}/image`)
        .set(bearer(author.token))
        .attach('file', png, { filename: 'a.png', contentType: 'image/png' })
        .expect(201);
      expect(commentPhoto.body.imageUrl).toMatch(/^\/uploads\/comments\//);
    });
  });

  describe('comments', () => {
    it('builds threads, newest first, and removes a whole thread with its author', async () => {
      const author = await registerUser('comment-author@example.com');
      const replier = await registerUser('comment-replier@example.com');
      const recipeId = await createRecipe(author.token);

      const root = (
        await http()
          .post(`/recipes/${recipeId}/comments`)
          .set(bearer(author.token))
          .send({ content: 'first' })
          .expect(201)
      ).body;
      const reply = (
        await http()
          .post(`/recipes/${recipeId}/comments`)
          .set(bearer(replier.token))
          .send({ content: 'reply', parentId: root.id })
          .expect(201)
      ).body;
      await http()
        .post(`/recipes/${recipeId}/comments`)
        .set(bearer(author.token))
        .send({ content: 'nested', parentId: reply.id })
        .expect(201);

      const tree = (await http().get(`/recipes/${recipeId}/comments`).expect(200)).body;
      expect(tree).toHaveLength(1);
      expect(tree[0].content).toBe('first');
      expect(tree[0].replies[0].content).toBe('reply');
      expect(tree[0].replies[0].replies[0].content).toBe('nested');

      // Only the author can delete; deleting a comment deletes its replies too.
      await http().delete(`/comments/${root.id}`).set(bearer(replier.token)).expect(403);
      await http().delete(`/comments/${root.id}`).set(bearer(author.token)).expect(200);
      expect((await http().get(`/recipes/${recipeId}/comments`).expect(200)).body).toEqual([]);
      await http().delete(`/comments/${root.id}`).set(bearer(author.token)).expect(404);
    });

    it('rejects comments on unknown recipes, unknown parents and parents from another recipe', async () => {
      const user = await registerUser('comment-guard@example.com');
      const recipeA = await createRecipe(user.token);
      const recipeB = await createRecipe(user.token);
      const onA = (
        await http().post(`/recipes/${recipeA}/comments`).set(bearer(user.token)).send({ content: 'on A' }).expect(201)
      ).body;

      await http().post('/recipes/no-such-recipe/comments').set(bearer(user.token)).send({ content: 'x' }).expect(404);
      await http()
        .post(`/recipes/${recipeA}/comments`)
        .set(bearer(user.token))
        .send({ content: 'x', parentId: 'no-such-comment' })
        .expect(404);
      await http()
        .post(`/recipes/${recipeB}/comments`)
        .set(bearer(user.token))
        .send({ content: 'cross-thread', parentId: onA.id })
        .expect(400);
      await http().post(`/recipes/${recipeA}/comments`).send({ content: 'anon' }).expect(401);
    });
  });

  describe('meal plan', () => {
    const entry = (recipeId: string) => ({
      recipeId,
      date: '2026-10-05T12:00:00.000Z',
      mealType: 'dinner',
      servings: 2,
    });

    it('lets a user plan, list and delete meals, privately', async () => {
      const alice = await registerUser('plan-alice@example.com');
      const bob = await registerUser('plan-bob@example.com');

      const created = await http().post('/meal-plan').set(bearer(alice.token)).send(entry(seedRecipeId)).expect(201);
      expect(created.body).toMatchObject({ userId: alice.id, recipeId: seedRecipeId, mealType: 'dinner', servings: 2 });

      expect((await http().get('/meal-plan').set(bearer(alice.token)).expect(200)).body).toHaveLength(1);
      expect((await http().get('/meal-plan').set(bearer(bob.token)).expect(200)).body).toEqual([]);

      await http().delete(`/meal-plan/${created.body.id}`).set(bearer(bob.token)).expect(403);
      await http().delete(`/meal-plan/${created.body.id}`).set(bearer(alice.token)).expect(200);
      await http().delete(`/meal-plan/${created.body.id}`).set(bearer(alice.token)).expect(404);
    });

    it('validates the entry and the recipe', async () => {
      const { token } = await registerUser('plan-invalid@example.com');

      await http()
        .post('/meal-plan')
        .set(bearer(token))
        .send({ ...entry(seedRecipeId), mealType: 'brunch' })
        .expect(400);
      await http()
        .post('/meal-plan')
        .set(bearer(token))
        .send({ ...entry(seedRecipeId), date: 'tomorrow' })
        .expect(400);
      await http().post('/meal-plan').set(bearer(token)).send(entry('no-such-recipe')).expect(404);
      await http().post('/meal-plan').send(entry(seedRecipeId)).expect(401);
    });
  });

  describe('profile and account', () => {
    it('updates the display name', async () => {
      const { token } = await registerUser('profile-name@example.com');
      const res = await http().patch('/auth/profile').set(bearer(token)).send({ name: '  New Name ' }).expect(200);
      expect(res.body.name).toBe('New Name');
      expect(res.body).not.toHaveProperty('passwordHash');
    });

    it('changes the password only with the correct current one', async () => {
      const { token } = await registerUser('profile-pw@example.com', 'old-password');

      await http()
        .post('/auth/change-password')
        .set(bearer(token))
        .send({ currentPassword: 'wrong-guess', newPassword: 'new-password' })
        .expect(400); // not 401: the app treats 401 as an expired session and logs out
      await http()
        .post('/auth/change-password')
        .set(bearer(token))
        .send({ currentPassword: 'old-password', newPassword: 'new-password' })
        .expect(200);

      await http().post('/auth/login').send({ email: 'profile-pw@example.com', password: 'old-password' }).expect(401);
      await http().post('/auth/login').send({ email: 'profile-pw@example.com', password: 'new-password' }).expect(201);
    });

    it('rejects an avatar that is not an image', async () => {
      const { token } = await registerUser('profile-avatar@example.com');
      await http()
        .post('/auth/avatar')
        .set(bearer(token))
        .attach('file', Buffer.from('not an image'), { filename: 'a.txt', contentType: 'text/plain' })
        .expect(400);
      await http().post('/auth/avatar').set(bearer(token)).expect(400); // no file at all
    });

    it('requires a token for every account endpoint', async () => {
      await http().patch('/auth/profile').send({ name: 'x' }).expect(401);
      await http().post('/auth/change-password').send({ currentPassword: 'a', newPassword: 'bbbbbb' }).expect(401);
      await http().delete('/auth/account').expect(401);
    });
  });
});
