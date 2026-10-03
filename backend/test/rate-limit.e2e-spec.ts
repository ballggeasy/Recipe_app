import { INestApplication } from '@nestjs/common';
import { rmSync } from 'fs';
import request from 'supertest';
import { uploadsRoot } from '../src/common/image-upload';
import { createTestApp } from './helpers/create-test-app';

describe('Rate limiting (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    // Limits are read per request, so lowering them here is enough (the shared setup raises them).
    process.env.RATE_LIMIT_PER_MINUTE = '5';
    process.env.AUTH_RATE_LIMIT_PER_MINUTE = '3';
    app = await createTestApp();
  });

  afterAll(async () => {
    process.env.RATE_LIMIT_PER_MINUTE = '100000';
    process.env.AUTH_RATE_LIMIT_PER_MINUTE = '100000';
    await app.close();
    rmSync(uploadsRoot(), { recursive: true, force: true });
  });

  const http = () => request(app.getHttpServer());

  it('blocks repeated login attempts so passwords cannot be brute-forced', async () => {
    const attempt = () => http().post('/auth/login').send({ email: 'victim@example.com', password: 'guess-guess' });

    for (let i = 0; i < 3; i++) await attempt().expect(401);

    const blocked = await attempt().expect(429);
    expect(blocked.body).toMatchObject({ statusCode: 429, error: 'Too Many Requests' });
  });

  it('applies a general limit to other routes', async () => {
    for (let i = 0; i < 5; i++) await http().get('/recipes').expect(200);
    await http().get('/recipes').expect(429);
  });

  it('never limits health checks or metrics', async () => {
    for (let i = 0; i < 12; i++) await http().get('/health').expect(200);
    for (let i = 0; i < 12; i++) await http().get('/health/ready').expect(200);
    for (let i = 0; i < 12; i++) await http().get('/metrics').expect(200);
  });
});
