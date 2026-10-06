import { ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { OAuth2Client } from 'google-auth-library';
import { GoogleTokenVerifier, googleClientIds } from '../src/auth/google-token-verifier';

/** Replaces Google's network call: the verifier is tested for what it asks and what it accepts. */
function verifierReturning(payload: Record<string, unknown> | Error) {
  const verifyIdToken = jest.spyOn(OAuth2Client.prototype, 'verifyIdToken').mockImplementation((async () => {
    if (payload instanceof Error) throw payload;
    return { getPayload: () => payload };
  }) as never);
  return { verifier: new GoogleTokenVerifier(), verifyIdToken };
}

describe('GoogleTokenVerifier', () => {
  const original = process.env.GOOGLE_CLIENT_IDS;
  afterEach(() => {
    jest.restoreAllMocks();
    if (original === undefined) delete process.env.GOOGLE_CLIENT_IDS;
    else process.env.GOOGLE_CLIENT_IDS = original;
  });

  it('reads the accepted client ids from GOOGLE_CLIENT_IDS', () => {
    process.env.GOOGLE_CLIENT_IDS = ' a.apps.googleusercontent.com , b.apps.googleusercontent.com,, ';
    expect(googleClientIds()).toEqual(['a.apps.googleusercontent.com', 'b.apps.googleusercontent.com']);
  });

  it('answers 503 instead of accepting anything when no client id is configured', async () => {
    delete process.env.GOOGLE_CLIENT_IDS;
    const { verifier, verifyIdToken } = verifierReturning({ sub: '1', email: 'a@b.c', email_verified: true });

    await expect(verifier.verify('token')).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(verifyIdToken).not.toHaveBeenCalled();
  });

  it('only accepts tokens issued to our own client ids', async () => {
    process.env.GOOGLE_CLIENT_IDS = 'web.apps.googleusercontent.com,android.apps.googleusercontent.com';
    const { verifier, verifyIdToken } = verifierReturning({ sub: '1', email: 'a@b.c', email_verified: true });

    await verifier.verify('token');

    expect(verifyIdToken).toHaveBeenCalledWith({
      idToken: 'token',
      audience: ['web.apps.googleusercontent.com', 'android.apps.googleusercontent.com'],
    });
  });

  it('returns the identity from a valid token', async () => {
    process.env.GOOGLE_CLIENT_IDS = 'web.apps.googleusercontent.com';
    const { verifier } = verifierReturning({
      sub: 'google-1',
      email: 'somchai@example.com',
      email_verified: true,
      name: 'Somchai',
      picture: 'https://example.com/p.jpg',
    });

    await expect(verifier.verify('token')).resolves.toEqual({
      googleId: 'google-1',
      email: 'somchai@example.com',
      name: 'Somchai',
      picture: 'https://example.com/p.jpg',
    });
  });

  it('answers 401 when Google rejects the token (bad signature, wrong audience, expired)', async () => {
    process.env.GOOGLE_CLIENT_IDS = 'web.apps.googleusercontent.com';
    const { verifier } = verifierReturning(new Error('Wrong recipient, payload audience != requiredAudience'));

    await expect(verifier.verify('token')).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it.each([
    ['an unverified email', { sub: '1', email: 'a@b.c', email_verified: false }],
    ['no email', { sub: '1', email_verified: true }],
    ['no subject', { email: 'a@b.c', email_verified: true }],
  ])('refuses a token with %s', async (_label, payload) => {
    process.env.GOOGLE_CLIENT_IDS = 'web.apps.googleusercontent.com';
    const { verifier } = verifierReturning(payload);

    await expect(verifier.verify('token')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
