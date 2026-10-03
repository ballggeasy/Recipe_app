import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Baseline: the schema TypeORM's `synchronize` used to create, so databases that already exist
 * (created by `synchronize`) and brand-new ones end up identical. Every statement is
 * IF NOT EXISTS, which makes this a no-op on an existing database.
 */
export class InitialSchema1790985600000 implements MigrationInterface {
  name = 'InitialSchema1790985600000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    const statements = [
      `CREATE TABLE IF NOT EXISTS "users" ("id" varchar PRIMARY KEY NOT NULL, "email" varchar NOT NULL, "passwordHash" varchar NOT NULL, "name" varchar NOT NULL, "profileImageUrl" text, "createdAt" datetime NOT NULL DEFAULT (datetime('now')), CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email"))`,
      `CREATE TABLE IF NOT EXISTS "recipes" ("id" varchar PRIMARY KEY NOT NULL, "name" varchar NOT NULL, "emoji" varchar NOT NULL, "imageUrl" varchar NOT NULL DEFAULT (''), "imageUrls" text NOT NULL DEFAULT ('[]'), "category" varchar NOT NULL, "country" varchar NOT NULL, "cookTimeMinutes" integer NOT NULL, "prepTimeMinutes" integer NOT NULL DEFAULT (10), "difficulty" varchar NOT NULL, "servings" integer NOT NULL DEFAULT (2), "ingredients" text NOT NULL DEFAULT ('[]'), "ingredientItems" text NOT NULL DEFAULT ('[]'), "steps" text NOT NULL DEFAULT ('[]'), "tips" text, "platingTips" text, "nutrition" text, "dietTags" text NOT NULL DEFAULT ('[]'), "season" varchar NOT NULL DEFAULT ('ตลอดปี'), "videoUrl" text, "isOfficial" boolean NOT NULL DEFAULT (1), "uploaderId" text, "uploaderName" text, "rating" float NOT NULL DEFAULT (0), "reviewCount" integer NOT NULL DEFAULT (0), "viewCount" integer NOT NULL DEFAULT (0), "isRecommended" boolean NOT NULL DEFAULT (0), "createdAt" datetime NOT NULL DEFAULT (datetime('now')))`,
      `CREATE TABLE IF NOT EXISTS "reviews" ("id" varchar PRIMARY KEY NOT NULL, "recipeId" varchar NOT NULL, "userId" varchar NOT NULL, "userName" varchar NOT NULL, "rating" float NOT NULL, "content" text NOT NULL, "imageUrls" text NOT NULL DEFAULT ('[]'), "likedByUserIds" text NOT NULL DEFAULT ('[]'), "isReported" boolean NOT NULL DEFAULT (0), "createdAt" datetime NOT NULL DEFAULT (datetime('now')))`,
      `CREATE TABLE IF NOT EXISTS "review_replies" ("id" varchar PRIMARY KEY NOT NULL, "reviewId" varchar NOT NULL, "userId" varchar NOT NULL, "userName" varchar NOT NULL, "content" text NOT NULL, "createdAt" datetime NOT NULL DEFAULT (datetime('now')), CONSTRAINT "FK_385273ae9fd7dc7313e9933cf57" FOREIGN KEY ("reviewId") REFERENCES "reviews" ("id") ON DELETE CASCADE ON UPDATE NO ACTION)`,
      `CREATE TABLE IF NOT EXISTS "comments" ("id" varchar PRIMARY KEY NOT NULL, "recipeId" varchar NOT NULL, "userId" varchar NOT NULL, "userName" varchar NOT NULL, "content" text NOT NULL, "imageUrl" text, "mentions" text NOT NULL DEFAULT ('[]'), "parentId" text, "createdAt" datetime NOT NULL DEFAULT (datetime('now')))`,
      `CREATE TABLE IF NOT EXISTS "favorites" ("id" varchar PRIMARY KEY NOT NULL, "userId" varchar NOT NULL, "recipeId" varchar NOT NULL, "createdAt" datetime NOT NULL DEFAULT (datetime('now')), CONSTRAINT "UQ_9d78e74219d7b9588440208b5bf" UNIQUE ("userId", "recipeId"))`,
      `CREATE TABLE IF NOT EXISTS "favorite_folders" ("id" varchar PRIMARY KEY NOT NULL, "userId" varchar NOT NULL, "name" varchar NOT NULL, "emoji" varchar NOT NULL DEFAULT ('📁'), "recipeIds" text NOT NULL DEFAULT ('[]'), "createdAt" datetime NOT NULL DEFAULT (datetime('now')))`,
      `CREATE TABLE IF NOT EXISTS "meal_plan_entries" ("id" varchar PRIMARY KEY NOT NULL, "userId" varchar NOT NULL, "recipeId" varchar NOT NULL, "date" datetime NOT NULL, "mealType" text NOT NULL, "servings" integer NOT NULL DEFAULT (1), "createdAt" datetime NOT NULL DEFAULT (datetime('now')))`,
    ];
    for (const sql of statements) await queryRunner.query(sql);
  }

  public async down(): Promise<void> {
    // Dropping every table would destroy all data; restore from a backup instead.
    throw new Error('The baseline migration cannot be reverted.');
  }
}
