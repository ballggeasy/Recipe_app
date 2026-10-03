import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import { configureApp } from '../../src/app.setup';

/**
 * Boots the real AppModule with the same HTTP configuration as src/main.ts (helmet, CORS, validation,
 * error filter). AppModule is imported lazily because ConfigModule reads the environment when the
 * module is first loaded, so a test can set env vars before calling this.
 */
export async function createTestApp(): Promise<NestExpressApplication> {
  const { AppModule } = await import('../../src/app.module');
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
  const app = moduleRef.createNestApplication<NestExpressApplication>();
  configureApp(app);
  await app.init();
  return app;
}
