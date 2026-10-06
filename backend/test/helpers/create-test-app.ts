import { NestExpressApplication } from '@nestjs/platform-express';
import { Test, TestingModuleBuilder } from '@nestjs/testing';
import { configureApp } from '../../src/app.setup';

/**
 * Boots the real AppModule with the same HTTP configuration as src/main.ts (helmet, CORS, validation,
 * error filter). AppModule is imported lazily because ConfigModule reads the environment when the
 * module is first loaded, so a test can set env vars before calling this. [customize] can swap
 * providers, e.g. `(b) => b.overrideProvider(NutritionEstimator).useValue(fake)`.
 */
export async function createTestApp(
  customize: (builder: TestingModuleBuilder) => TestingModuleBuilder = (builder) => builder,
): Promise<NestExpressApplication> {
  const { AppModule } = await import('../../src/app.module');
  const moduleRef = await customize(Test.createTestingModule({ imports: [AppModule] })).compile();
  const app = moduleRef.createNestApplication<NestExpressApplication>();
  configureApp(app);
  await app.init();
  return app;
}
