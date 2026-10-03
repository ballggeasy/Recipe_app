import { validateEnv } from '../src/config/env.validation';

const strongSecret = 'a'.repeat(48);

describe('validateEnv', () => {
  it('rejects a missing or blank JWT_SECRET in every environment', () => {
    expect(() => validateEnv({})).toThrow(/JWT_SECRET is not set/);
    expect(() => validateEnv({ JWT_SECRET: '   ' })).toThrow(/JWT_SECRET is not set/);
    expect(() => validateEnv({ NODE_ENV: 'production' })).toThrow(/JWT_SECRET is not set/);
    expect(() => validateEnv({ NODE_ENV: 'development' })).toThrow(/JWT_SECRET is not set/);
  });

  it('accepts any non-empty secret outside production so dev and tests stay easy', () => {
    const env = { JWT_SECRET: 'dev-secret', NODE_ENV: 'test' };
    expect(validateEnv(env)).toBe(env);
    expect(() => validateEnv({ JWT_SECRET: 'dev-secret' })).not.toThrow();
  });

  it('rejects known placeholder secrets in production', () => {
    expect(() =>
      validateEnv({ JWT_SECRET: 'change-this-secret-in-production', NODE_ENV: 'production' }),
    ).toThrow(/placeholder/);
    expect(() => validateEnv({ JWT_SECRET: 'ChangeMe', NODE_ENV: 'production' })).toThrow(/placeholder/);
  });

  it('rejects short secrets in production', () => {
    expect(() => validateEnv({ JWT_SECRET: 'too-short', NODE_ENV: 'production' })).toThrow(/at least 32/);
  });

  it('accepts a long random secret in production', () => {
    expect(() => validateEnv({ JWT_SECRET: strongSecret, NODE_ENV: 'production' })).not.toThrow();
  });
});
