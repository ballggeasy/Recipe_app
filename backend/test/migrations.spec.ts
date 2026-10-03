import { mkdtempSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { DataSource, DataSourceOptions } from 'typeorm';
import { databaseOptions, entities } from '../src/database/database.config';

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
