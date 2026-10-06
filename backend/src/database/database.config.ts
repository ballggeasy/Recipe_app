import { SqliteConnectionOptions } from 'typeorm/driver/sqlite/SqliteConnectionOptions';
import { Comment } from '../comments/comment.entity';
import { Favorite } from '../favorites/favorite.entity';
import { FavoriteFolder } from '../favorites/folder.entity';
import { MealPlanEntry } from '../meal-plan/meal-plan-entry.entity';
import { Recipe } from '../recipes/recipe.entity';
import { Review, ReviewReply } from '../reviews/review.entity';
import { User } from '../users/user.entity';
import { InitialSchema1790985600000 } from './migrations/1790985600000-InitialSchema';
import { AddLookupIndexes1790985700000 } from './migrations/1790985700000-AddLookupIndexes';
import { AddGoogleId1790985800000 } from './migrations/1790985800000-AddGoogleId';
import { useImmediateTransactions } from './immediate-transactions';
import { useSerializedTransactions } from './serialized-transactions';

export const entities = [User, Recipe, Favorite, FavoriteFolder, Review, ReviewReply, Comment, MealPlanEntry];

/** Listed explicitly (not globbed) so ts-node, ts-jest and the compiled dist/ all load the same set, in order. */
export const migrations = [InitialSchema1790985600000, AddLookupIndexes1790985700000, AddGoogleId1790985800000];

/**
 * Several backend replicas (docker-compose runs two by default, behind nginx) share this one SQLite
 * file on the same host. WAL lets readers run while another process writes, and the busy timeout makes
 * a writer wait for the single write lock instead of failing at once with SQLITE_BUSY.
 * The file must live on a local disk (a Docker volume is fine, a network share is not).
 */
const BUSY_TIMEOUT_MS = 5000;

/**
 * The schema is owned by migrations: they run on boot and `synchronize` stays off, so a changed
 * entity can never alter or drop columns of a live database by itself. To change the schema, add a
 * migration (see docs/DATABASE.md).
 */
export function databaseOptions(): SqliteConnectionOptions {
  useImmediateTransactions();
  useSerializedTransactions();
  return {
    type: 'sqlite',
    database: process.env.DB_PATH ?? './data/app.sqlite',
    entities,
    migrations,
    migrationsRun: true,
    synchronize: false,
    enableWAL: true,
    busyTimeout: BUSY_TIMEOUT_MS,
  };
}
