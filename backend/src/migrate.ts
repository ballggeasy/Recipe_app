import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { JsonLogger } from './common/json-logger';

/**
 * One-shot job that brings the database up to date and seeds it, then exits.
 *
 * With several replicas starting at once, each would otherwise try to run the same pending
 * migrations (and the first-time seed) and collide on SQLite's single write lock. docker-compose
 * runs this once, to completion, before any replica starts; the replicas then find nothing to do.
 * Booting the application context is enough: TypeORM runs the migrations when it connects and
 * SeedService seeds an empty catalog on bootstrap.
 */
async function migrate() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: process.env.NODE_ENV === 'production' ? new JsonLogger() : undefined,
  });
  await app.close();
  new Logger('Migrate').log('Database is up to date');
}

migrate().catch((error) => {
  console.error(error);
  process.exit(1);
});
