import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AllExceptionsFilter } from './common/all-exceptions.filter';
import { httpLoggerMiddleware } from './common/http-logger.middleware';
import { uploadsRoot } from './common/image-upload';
import { requestIdMiddleware } from './common/request-id.middleware';

/** `CORS_ORIGINS=https://a.example,https://b.example` -> list; empty/unset -> []. */
export function parseOrigins(value: string | undefined): string[] {
  return (value ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

/**
 * Everything main.ts and the e2e tests share, so tests exercise the same HTTP behaviour as the
 * real server (headers, CORS, validation, error shape).
 */
export function configureApp(app: NestExpressApplication): void {
  const env = process.env;

  // Behind a reverse proxy the client IP (used by rate limiting) comes from X-Forwarded-For.
  // TRUST_PROXY = number of proxy hops in front of the app; leave unset when exposed directly.
  const hops = Number(env.TRUST_PROXY);
  if (Number.isInteger(hops) && hops > 0) app.set('trust proxy', hops);

  app.use(requestIdMiddleware);
  if (env.NODE_ENV !== 'test') app.use(httpLoggerMiddleware);

  app.use(
    helmet({
      // The Flutter web app loads uploaded images from this API on another origin.
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );

  // Native apps don't use CORS. Browsers (Flutter web) are allowed only from CORS_ORIGINS in
  // production; outside production any origin works so local dev needs no setup.
  const origins = parseOrigins(env.CORS_ORIGINS);
  if (origins.length > 0) app.enableCors({ origin: origins });
  else if (env.NODE_ENV !== 'production') app.enableCors();

  app.useStaticAssets(uploadsRoot(), { prefix: '/uploads/' });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));
  app.useGlobalFilters(new AllExceptionsFilter());
}
