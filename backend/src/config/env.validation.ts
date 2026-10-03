/** Values that ship in examples/docs and must never sign real tokens in production. */
const PLACEHOLDER_SECRETS = new Set(['change-this-secret-in-production', 'changeme', 'secret', 'jwt-secret']);

export const MIN_PRODUCTION_SECRET_LENGTH = 32;

/**
 * Fails fast at boot (ConfigModule `validate`) instead of silently running with a guessable
 * JWT secret. Strict in production, only "must be set" elsewhere so local dev and tests stay easy.
 */
export function validateEnv(config: Record<string, unknown>): Record<string, unknown> {
  const secret = typeof config.JWT_SECRET === 'string' ? config.JWT_SECRET.trim() : '';
  if (!secret) {
    throw new Error(
      'JWT_SECRET is not set. Generate one with: node -e "console.log(require(\'crypto\').randomBytes(48).toString(\'hex\'))"',
    );
  }

  if (config.NODE_ENV === 'production') {
    if (PLACEHOLDER_SECRETS.has(secret.toLowerCase())) {
      throw new Error('JWT_SECRET is a well-known placeholder; set a unique random value in production.');
    }
    if (secret.length < MIN_PRODUCTION_SECRET_LENGTH) {
      throw new Error(`JWT_SECRET must be at least ${MIN_PRODUCTION_SECRET_LENGTH} characters in production.`);
    }
  }

  return config;
}
