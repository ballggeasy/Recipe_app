import { INestApplication } from '@nestjs/common';
import { rmSync } from 'fs';
import request from 'supertest';
import { uploadsRoot } from '../src/common/image-upload';
import { createTestApp } from './helpers/create-test-app';

describe('HTTP hardening, error shape and health (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await app.close();
    rmSync(uploadsRoot(), { recursive: true, force: true });
  });

  const http = () => request(app.getHttpServer());

  describe('error responses', () => {
    it('uses one JSON shape for HTTP errors and keeps the message the client shows', async () => {
      const res = await http().get('/recipes/does-not-exist').expect(404);

      expect(res.body).toMatchObject({
        statusCode: 404,
        error: 'Not Found',
        message: 'ไม่พบสูตรอาหารนี้',
        path: '/recipes/does-not-exist',
      });
      expect(typeof res.body.timestamp).toBe('string');
      expect(res.body.requestId).toBe(res.headers['x-request-id']);
    });

    it('keeps validation messages as a list so the app can join them', async () => {
      const res = await http().post('/auth/register').send({ name: '', email: 'bad', password: '1' }).expect(400);

      expect(res.body.statusCode).toBe(400);
      expect(Array.isArray(res.body.message)).toBe(true);
      expect(res.body.message.length).toBeGreaterThan(0);
    });

    it('reports unknown routes in the same shape', async () => {
      const res = await http().get('/no-such-route').expect(404);
      expect(res.body).toMatchObject({ statusCode: 404, path: '/no-such-route' });
    });
  });

  describe('request id', () => {
    it('generates one when the client sends none', async () => {
      const res = await http().get('/health').expect(200);
      expect(res.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
    });

    it('reuses a safe client-supplied id', async () => {
      const res = await http().get('/health').set('X-Request-Id', 'trace-abc_123').expect(200);
      expect(res.headers['x-request-id']).toBe('trace-abc_123');
    });

    it('replaces an unsafe client-supplied id', async () => {
      const res = await http().get('/health').set('X-Request-Id', 'bad id with spaces').expect(200);
      expect(res.headers['x-request-id']).not.toBe('bad id with spaces');
    });
  });

  describe('security headers', () => {
    it('sets helmet defaults but still lets other origins load uploaded images', async () => {
      const res = await http().get('/health').expect(200);

      expect(res.headers['x-content-type-options']).toBe('nosniff');
      expect(res.headers['x-powered-by']).toBeUndefined();
      expect(res.headers['cross-origin-resource-policy']).toBe('cross-origin');
    });
  });

  describe('health', () => {
    it('keeps the liveness response unchanged', async () => {
      const res = await http().get('/health').expect(200);
      expect(res.body).toEqual({ status: 'ok', revision: process.env.APP_REVISION || 'dev' });
    });

    it('reports ready when the database answers', async () => {
      const res = await http().get('/health/ready').expect(200);
      expect(res.body).toEqual({ status: 'ready', revision: process.env.APP_REVISION || 'dev' });
    });
  });

  describe('recipe mass assignment', () => {
    it('rejects isRecommended: users cannot promote their own recipes', async () => {
      const reg = await http()
        .post('/auth/register')
        .send({ name: 'Promoter', email: 'promoter@example.com', password: 'secret123' })
        .expect(201);

      await http()
        .post('/recipes')
        .set('Authorization', `Bearer ${reg.body.accessToken}`)
        .send({
          name: 'Promoted',
          emoji: '🍜',
          category: 'อาหารจานเดียว',
          country: 'ไทย',
          cookTimeMinutes: 5,
          difficulty: 'ง่าย',
          ingredients: ['น้ำ'],
          steps: ['ต้ม'],
          isRecommended: true,
        })
        .expect(400);
    });
  });
});
