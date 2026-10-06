import { mkdtempSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { DataSource, DataSourceOptions } from 'typeorm';
import { databaseOptions, entities, migrations } from '../src/database/database.config';

const tableNames = async (ds: DataSource): Promise<string[]> =>
  (
    await ds.query("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
  ).map((row: { name: string }) => row.name);

describe('database migrations', () => {
  const opened: DataSource[] = [];
  const open = async (options: DataSourceOptions) => {
    const ds = new DataSource(options);
    opened.push(ds);
    await ds.initialize();
    return ds;
  };

  // Windows can't delete a SQLite file that is still open, so close everything before cleaning up.
  const closeAll = async () => {
    while (opened.length) {
      const ds = opened.pop()!;
      if (ds.isInitialized) await ds.destroy();
    }
  };
  afterEach(closeAll);

  it('build the full schema on an empty database, with no drift from the entities', async () => {
    const ds = await open({ ...databaseOptions(), database: ':memory:' });

    expect(await tableNames(ds)).toEqual(
      expect.arrayContaining([
        'comments',
        'favorite_folders',
        'favorites',
        'meal_plan_entries',
        'migrations',
        'recipes',
        'review_replies',
        'reviews',
        'users',
      ]),
    );
    // If an entity changes without a matching migration, TypeORM would still need to alter the schema.
    const pending = await ds.driver.createSchemaBuilder().log();
    expect(pending.upQueries.map((q) => q.query)).toEqual([]);
  });

  it('give the hot lookups an index instead of a full table scan', async () => {
    const ds = await open({ ...databaseOptions(), database: ':memory:' });
    const plan = async (sql: string) =>
      (await ds.query(`EXPLAIN QUERY PLAN ${sql}`)).map((row: { detail: string }) => row.detail).join(' | ');

    expect(await plan(`SELECT * FROM reviews WHERE recipeId = 'r' ORDER BY createdAt DESC`)).toContain(
      'IDX_reviews_recipe_created',
    );
    expect(await plan(`SELECT * FROM comments WHERE recipeId = 'r' ORDER BY createdAt ASC`)).toContain(
      'IDX_comments_recipe_created',
    );
    expect(await plan(`SELECT * FROM review_replies WHERE reviewId = 'x'`)).toContain('IDX_review_replies_review');
    expect(await plan(`SELECT * FROM meal_plan_entries WHERE userId = 'u' ORDER BY date ASC`)).toContain(
      'IDX_meal_plan_user_date',
    );
    expect(await plan(`SELECT * FROM favorite_folders WHERE userId = 'u'`)).toContain('IDX_favorite_folders_user');
    expect(await plan(`SELECT * FROM recipes ORDER BY createdAt DESC`)).toContain('IDX_recipes_created');
  });

  it('leave a database created by the old `synchronize` untouched and keep its data', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'recipe-migrations-'));
    const file = join(dir, 'legacy.sqlite');
    try {
      const legacy = await open({ type: 'sqlite', database: file, entities, synchronize: true });
      await legacy.query(
        `INSERT INTO users (id, email, passwordHash, name) VALUES ('u1', 'old@example.com', 'hash', 'Old User')`,
      );
      await legacy.destroy();

      const upgraded = await open({ ...databaseOptions(), database: file });

      const users = await upgraded.query('SELECT email, name FROM users');
      expect(users).toEqual([{ email: 'old@example.com', name: 'Old User' }]);
      const pending = await upgraded.driver.createSchemaBuilder().log();
      expect(pending.upQueries.map((q) => q.query)).toEqual([]);
      const applied = await upgraded.query('SELECT name FROM migrations');
      expect(applied.length).toBeGreaterThan(0);
    } finally {
      await closeAll();
      rmSync(dir, { recursive: true, force: true });
    }
  });

  it('fill in nutrition for the official sample recipes that had none, and nothing else', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'recipe-migrations-'));
    const file = join(dir, 'nutrition.sqlite');
    const before = migrations.filter((m) => m.name !== 'AddOfficialRecipeNutrition1791400000000');
    const insert = (id: string, name: string, isOfficial: boolean, nutrition: string | null) =>
      `INSERT INTO recipes (id, name, emoji, category, country, cookTimeMinutes, difficulty, isOfficial, nutrition)
       VALUES ('${id}', '${name}', '🍽️', 'c', 'c', 10, 'ง่าย', ${isOfficial ? 1 : 0}, ${nutrition ? `'${nutrition}'` : 'NULL'})`;
    try {
      const old = await open({ ...databaseOptions(), database: file, migrations: before });
      await old.query(insert('tiramisu', 'ทีรามิสุ', true, null));
      await old.query(
        insert('takoyaki', 'ทาโคยากิ', true, '{"calories":1,"protein":1,"fat":1,"carbs":1,"sugar":1,"sodium":1}'),
      );
      await old.query(insert('copy', 'กิมจิจิเก', false, null));
      await old.destroy();

      const upgraded = await open({ ...databaseOptions(), database: file });
      const nutritionOf = async (id: string) =>
        JSON.parse((await upgraded.query(`SELECT nutrition FROM recipes WHERE id = '${id}'`))[0].nutrition ?? 'null');

      expect(await nutritionOf('tiramisu')).toEqual({
        calories: 1140,
        protein: 18,
        fat: 66,
        carbs: 116,
        sugar: 75,
        sodium: 180,
      });
      expect((await nutritionOf('takoyaki')).calories).toBe(1);
      expect(await nutritionOf('copy')).toBeNull();

      await upgraded.undoLastMigration();
      expect(await nutritionOf('tiramisu')).toBeNull();
      expect((await nutritionOf('takoyaki')).calories).toBe(1);
    } finally {
      await closeAll();
      rmSync(dir, { recursive: true, force: true });
    }
  });

  it('are idempotent: booting twice runs nothing the second time', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'recipe-migrations-'));
    const file = join(dir, 'twice.sqlite');
    try {
      const first = await open({ ...databaseOptions(), database: file });
      const appliedFirst = (await first.query('SELECT name FROM migrations')).length;
      await first.destroy();

      const second = await open({ ...databaseOptions(), database: file });
      expect(await second.showMigrations()).toBe(false);
      expect((await second.query('SELECT name FROM migrations')).length).toBe(appliedFirst);
    } finally {
      await closeAll();
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
