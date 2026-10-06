import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { AppModule } from './app.module';
import { JsonLogger } from './common/json-logger';
import { RecipesService } from './recipes/recipes.service';

/**
 * One-off job that fills in AI nutrition estimates, e.g. for the sample recipes that never had any.
 *
 *   node dist/estimate-nutrition.js                  recipes without nutrition only
 *   node dist/estimate-nutrition.js --all            every recipe, replacing existing values (hand-entered ones too)
 *   node dist/estimate-nutrition.js --photos <dir>   use <dir>/<recipe id>.jpg (or .png/.webp) as the photo
 *
 * --photos is for the sample recipes: their image URLs point at Wikimedia thumbnails that no longer
 * load, and their photos only ship inside the app. Without a photo the estimate uses the ingredients.
 * Needs AI_API_KEY (see NutritionEstimator). Runs one recipe at a time and carries on past failures.
 */
async function estimateNutrition() {
  const all = process.argv.includes('--all');
  const photosArg = process.argv.indexOf('--photos');
  const photosDir = photosArg >= 0 ? process.argv[photosArg + 1] : undefined;

  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: process.env.NODE_ENV === 'production' ? new JsonLogger() : undefined,
  });
  const logger = new Logger('EstimateNutrition');
  const recipes = app.get(RecipesService);

  const pending = await recipes.findForNutritionBackfill(all);
  logger.log(`Estimating nutrition for ${pending.length} recipe(s)`);
  let failed = 0;
  for (const recipe of pending) {
    try {
      const photo = photosDir ? findPhoto(photosDir, recipe.id) : undefined;
      const { nutrition } = await recipes.saveNutritionEstimate(recipe, photo);
      logger.log(`${recipe.name}: ${nutrition?.calories} kcal per serving${photo ? ' (photo from --photos)' : ''}`);
    } catch (error) {
      failed += 1;
      logger.error(`${recipe.name}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  await app.close();
  logger.log(`Done: ${pending.length - failed} estimated, ${failed} failed`);
  if (failed > 0) process.exitCode = 1;
}

function findPhoto(dir: string, recipeId: string): Buffer | undefined {
  for (const ext of ['.jpg', '.jpeg', '.png', '.webp']) {
    const file = join(dir, `${recipeId}${ext}`);
    if (existsSync(file)) return readFileSync(file);
  }
  return undefined;
}

estimateNutrition().catch((error) => {
  console.error(error);
  process.exit(1);
});
