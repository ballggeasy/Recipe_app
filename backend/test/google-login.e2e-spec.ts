import { UnauthorizedException } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { configureApp } from '../src/app.setup';
import { GoogleIdentity, GoogleTokenVerifier } from '../src/auth/google-token-verifier';

/**
 * POST /auth/google through the real HTTP stack (validation, rate limit, JWT guard, database). Only
 * the call to Google is replaced: a token is "valid" when the fake knows it.
 */
describe('Sign in with Google (e2e)', () => {
  let app: NestExpressApplication;
  const tokens = new Map<string, GoogleIdentity>();

  beforeAll(async () => {
    const { AppModule } = await import('../src/app.module');
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(GoogleTokenVerifier)
      .useValue({
        verify: async (idToken: string) => {
          const identity = tokens.get(idToken);
          if (!identity) {
            throw new UnauthorizedException('ยืนยันตัวตนกับ Google ไม่สำเร็จ');
          }
          return identity;
        },
      })
      .compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
  });

  afterAll(() => app.close());

  const http = () => request(app.getHttpServer());

  it('signs a new Google user up and the token works on protected routes', async () => {
    tokens.set('token-new', {
      googleId: 'g-new',
      email: 'New.User@Example.com',
      name: 'New User',
      picture: 'https://lh3.googleusercontent.com/a/new',
    });

    const res = await http().post('/auth/google').send({ idToken: 'token-new' }).expect(200);

    expect(res.body.user).toMatchObject({
      email: 'new.user@example.com',
      name: 'New User',
      profileImageUrl: 'https://lh3.googleusercontent.com/a/new',
    });
    expect(res.body.user).not.toHaveProperty('passwordHash');
    expect(res.body.user).not.toHaveProperty('googleId');

    const me = await http().get('/auth/me').set('Authorization', `Bearer ${res.body.accessToken}`).expect(200);
    expect(me.body.id).toBe(res.body.user.id);
  });

  it('signs the same person in again as the same user', async () => {
    tokens.set('token-again', { googleId: 'g-again', email: 'again@example.com', name: 'Again', picture: null });

    const first = await http().post('/auth/google').send({ idToken: 'token-again' }).expect(200);
    const second = await http().post('/auth/google').send({ idToken: 'token-again' }).expect(200);

    expect(second.body.user.id).toBe(first.body.user.id);
  });

  it('links to the account registered with the same email and keeps the password working', async () => {
    const registered = await http()
      .post('/auth/register')
      .send({ name: 'Linked', email: 'linked@example.com', password: 'secret123' })
      .expect(201);
    tokens.set('token-linked', {
      googleId: 'g-linked',
      email: 'linked@example.com',
      name: 'Other Name',
      picture: null,
    });

    const res = await http().post('/auth/google').send({ idToken: 'token-linked' }).expect(200);

    expect(res.body.user.id).toBe(registered.body.user.id);
    expect(res.body.user.name).toBe('Linked');
    await http().post('/auth/login').send({ email: 'linked@example.com', password: 'secret123' }).expect(201);
  });

  it('gives a Google-only account no way to log in with a password', async () => {
    tokens.set('token-nopass', { googleId: 'g-nopass', email: 'nopass@example.com', name: 'No Pass', picture: null });
    await http().post('/auth/google').send({ idToken: 'token-nopass' }).expect(200);

    await http().post('/auth/login').send({ email: 'nopass@example.com', password: '' }).expect(401);
    await http().post('/auth/login').send({ email: 'nopass@example.com', password: 'secret123' }).expect(401);
  });

  it('refuses a token Google does not accept', async () => {
    const res = await http().post('/auth/google').send({ idToken: 'forged' }).expect(401);
    expect(res.body).not.toHaveProperty('accessToken');
  });

  it('rejects a body without an id token, or with extra fields', async () => {
    await http().post('/auth/google').send({}).expect(400);
    await http().post('/auth/google').send({ idToken: '' }).expect(400);
    await http()
      .post('/auth/google')
      .send({ idToken: 'x'.repeat(5000) })
      .expect(400);
    await http().post('/auth/google').send({ idToken: 'token-new', email: 'a@b.c' }).expect(400);
  });
});
