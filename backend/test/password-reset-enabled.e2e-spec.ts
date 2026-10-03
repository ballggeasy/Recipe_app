import { INestApplication } from '@nestjs/common';
import { rmSync } from 'fs';
import request from 'supertest';
import { uploadsRoot } from '../src/common/image-upload';
import { createTestApp } from './helpers/create-test-app';

// ConfigModule reads the environment when AppModule is first loaded, so the opt-in flag has to be
// set before AppModule is imported. That is why this lives in its own file (own module registry).
describe('Password reset with ALLOW_INSECURE_PASSWORD_RESET=true (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    process.env.ALLOW_INSECURE_PASSWORD_RESET = 'true';
    app = await createTestApp();
  });

  afterAll(async () => {
    delete process.env.ALLOW_INSECURE_PASSWORD_RESET;
    await app.close();
    rmSync(uploadsRoot(), { recursive: true, force: true });
  });

  it('lets local development reset a password by email', async () => {
    const http = () => request(app.getHttpServer());
    await http()
      .post('/auth/register')
      .send({ name: 'Dev', email: 'dev@example.com', password: 'old-password' })
      .expect(201);

    const exists = await http().get('/auth/exists/dev@example.com').expect(200);
    expect(exists.body).toEqual({ exists: true });

    await http()
      .post('/auth/reset-password')
      .send({ email: 'dev@example.com', newPassword: 'new-password' })
      .expect(200);

    await http().post('/auth/login').send({ email: 'dev@example.com', password: 'old-password' }).expect(401);
    await http().post('/auth/login').send({ email: 'dev@example.com', password: 'new-password' }).expect(201);
  });
});
