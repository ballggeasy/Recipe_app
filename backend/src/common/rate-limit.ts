/**
 * Rate limits are resolved per request from the environment, so they can be tuned (or raised in
 * tests) without code changes. Counted per client IP, per route, over a one-minute window.
 */
const WINDOW_MS = 60_000;

const fromEnv = (name: string, fallback: number) => () => {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
};

/** Applies to every route unless it opts out with @SkipThrottle(). */
export const DEFAULT_RATE_LIMIT = { limit: fromEnv('RATE_LIMIT_PER_MINUTE', 120), ttl: WINDOW_MS };

/**
 * Stricter limit for endpoints that check or change credentials (bcrypt is CPU-heavy, and these are
 * the brute-force targets). Use as `@Throttle(AUTH_RATE_LIMIT)`.
 */
export const AUTH_RATE_LIMIT = {
  default: { limit: fromEnv('AUTH_RATE_LIMIT_PER_MINUTE', 10), ttl: WINDOW_MS },
};

/** Endpoints that call a paid AI model on every request. Use as `@Throttle(AI_RATE_LIMIT)`. */
export const AI_RATE_LIMIT = {
  default: { limit: fromEnv('AI_RATE_LIMIT_PER_MINUTE', 5), ttl: WINDOW_MS },
};
