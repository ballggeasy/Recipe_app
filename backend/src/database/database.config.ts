import { SqliteConnectionOptions } from 'typeorm/driver/sqlite/SqliteConnectionOptions';
import { Comment } from '../comments/comment.entity';
import { Favorite } from '../favorites/favorite.entity';
import { FavoriteFolder } from '../favorites/folder.entity';
import { MealPlanEntry } from '../meal-plan/meal-plan-entry.entity';
import { Recipe } from '../recipes/recipe.entity';
import { Review, ReviewReply } from '../reviews/review.entity';
import { User } from '../users/user.entity';
import { InitialSchema1790985600000 } from './migrations/1790985600000-InitialSchema';

export const entities = [User, Recipe, Favorite, FavoriteFolder, Review, ReviewReply, Comment, MealPlanEntry];

/** Listed explicitly (not globbed) so ts-node, ts-jest and the compiled dist/ all load the same set, in order. */
export const migrations = [InitialSchema1790985600000];

/**
 * The schema is owned by migrations: they run on boot and `synchronize` stays off, so a changed
 * entity can never alter or drop columns of a live database by itself. To change the schema, add a
 * migration (see docs/DATABASE.md).
 */
export function databaseOptions(): SqliteConnectionOptions {
  return {
    type: 'sqlite',
    database: process.env.DB_PATH ?? './data/app.sqlite',
    entities,
    migrations,
    migrationsRun: true,
    synchronize: false,
  };
}
