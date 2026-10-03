import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import { JsonLogger } from './common/json-logger';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    // One JSON object per log line in production so logs can be shipped and queried.
    logger: process.env.NODE_ENV === 'production' ? new JsonLogger() : undefined,
  });
  configureApp(app);
  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  new Logger('Bootstrap').log(`Backend listening on http://localhost:${port}`);
}
bootstrap();
