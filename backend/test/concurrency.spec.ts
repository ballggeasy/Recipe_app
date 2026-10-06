import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { DataSource } from 'typeorm';
import { databaseOptions } from '../src/database/database.config';

/**
 * The load balancer runs several backend processes against one SQLite file. This opens the same
 * file through independent connections (as the replicas do) and writes from all of them at once.
 * Without WAL and a busy timeout this fails with SQLITE_BUSY.
 */
describe('several connections sharing one database file', () => {
  let dir: string;
  const opened: DataSource[] = [];

  const open = async (database: string) => {
    const ds = await new DataSource({ ...databaseOptions(), database }).initialize();
    opened.push(ds);
    return ds;
  };

  beforeEach(() => {
    dir = mkdtempSync(join(tmpdir(), 'recipe-concurrency-'));
  });

  afterEach(async () => {
    // Windows can't delete a SQLite file that is still open.
    while (opened.length) await opened.pop()!.destroy();
    rmSync(dir, { recursive: true, force: true });
  });

  it('runs in WAL mode with a busy timeout', async () => {
    const ds = await open(join(dir, 'app.sqlite'));

    expect(await ds.query('PRAGMA journal_mode')).toEqual([{ journal_mode: 'wal' }]);
    expect(await ds.query('PRAGMA busy_timeout')).toEqual([{ timeout: 5000 }]);
  });

  it('makes a writer wait for the write lock instead of failing with SQLITE_BUSY', async () => {
    const file = join(dir, 'app.sqlite');
    const slow = await open(file);
    const other = await open(file);
    await slow.query('CREATE TABLE counter_test (n INTEGER NOT NULL)');

    // One replica holds the write lock for longer than sqlite3's own 1 second default timeout
    // (a long request or a slow disk); another replica wants to write meanwhile.
    const holder = slow.transaction(async (manager) => {
      await manager.query('INSERT INTO counter_test (n) VALUES (1)');
      await new Promise((resolve) => setTimeout(resolve, 1500));
    });
    await new Promise((resolve) => setTimeout(resolve, 200));
    await other.query('INSERT INTO counter_test (n) VALUES (2)');
    await holder;

    expect(await other.query('SELECT n FROM counter_test ORDER BY n')).toEqual([{ n: 1 }, { n: 2 }]);
  });

  it('keeps every row when all connections write in parallel', async () => {
    const file = join(dir, 'app.sqlite');
    const first = await open(file);
    const replicas = [first, await open(file), await open(file)];
    await first.query('CREATE TABLE counter_test (replica INTEGER NOT NULL, n INTEGER NOT NULL)');

    const WRITES_PER_REPLICA = 100;
    await Promise.all(
      replicas.map(async (ds, replica) => {
        for (let n = 0; n < WRITES_PER_REPLICA; n++) {
          await ds.query('INSERT INTO counter_test (replica, n) VALUES (?, ?)', [replica, n]);
        }
      }),
    );

    const [{ total }] = await first.query('SELECT COUNT(*) AS total FROM counter_test');
    expect(total).toBe(replicas.length * WRITES_PER_REPLICA);
  });

  it('lets a second connection read while another is mid-write', async () => {
    const file = join(dir, 'app.sqlite');
    const writer = await open(file);
    const reader = await open(file);
    await writer.query('CREATE TABLE counter_test (n INTEGER NOT NULL)');
    await writer.query('INSERT INTO counter_test (n) VALUES (1)');

    const runner = writer.createQueryRunner();
    await runner.connect();
    await runner.startTransaction();
    await runner.query('INSERT INTO counter_test (n) VALUES (2)');
    try {
      // The uncommitted row is invisible, and the read does not wait for the write lock.
      const rows = await reader.query('SELECT n FROM counter_test ORDER BY n');
      expect(rows).toEqual([{ n: 1 }]);
    } finally {
      await runner.commitTransaction();
      await runner.release();
    }
  });

  it("runs one process's simultaneous transactions one after another instead of failing", async () => {
    // TypeORM shares one SQLite connection per DataSource, so two transactions started at the same
    // moment both sent BEGIN on it ("cannot start a transaction within a transaction").
    const ds = await open(join(dir, 'app.sqlite'));
    await ds.query('CREATE TABLE counter_test (n INTEGER NOT NULL)');

    const results = await Promise.allSettled(
      [1, 2, 3, 4, 5].map((n) =>
        ds.transaction(async (manager) => {
          await manager.query('INSERT INTO counter_test (n) VALUES (?)', [n]);
          await new Promise((resolve) => setTimeout(resolve, 20));
          if (n === 3) throw new Error('rolled back on purpose');
        }),
      ),
    );

    expect(results.map((r) => r.status)).toEqual(['fulfilled', 'fulfilled', 'rejected', 'fulfilled', 'fulfilled']);
    // The failed one's ROLLBACK only undid its own insert.
    expect(await ds.query('SELECT n FROM counter_test ORDER BY n')).toEqual([{ n: 1 }, { n: 2 }, { n: 4 }, { n: 5 }]);
  });

  it('lets a transaction start another one inside it without waiting for itself', async () => {
    const ds = await open(join(dir, 'app.sqlite'));
    await ds.query('CREATE TABLE counter_test (n INTEGER NOT NULL)');

    await ds.transaction(async (outer) => {
      await outer.query('INSERT INTO counter_test (n) VALUES (1)');
      await outer.transaction(async (inner) => inner.query('INSERT INTO counter_test (n) VALUES (2)'));
    });

    expect(await ds.query('SELECT n FROM counter_test ORDER BY n')).toEqual([{ n: 1 }, { n: 2 }]);
  });

  it('does not fail a transaction that reads first when another connection commits a write meanwhile', async () => {
    // TypeORM's save() starts a transaction and loads the existing row before writing. With a plain
    // `BEGIN` SQLite then refuses the write at once (SQLITE_BUSY, the busy timeout does not apply
    // because the read snapshot is stale). Transactions must take the write lock when they start.
    const file = join(dir, 'app.sqlite');
    const reader = await open(file);
    const writer = await open(file);
    await reader.query('CREATE TABLE counter_test (n INTEGER NOT NULL)');

    const readThenWrite = reader.transaction(async (manager) => {
      await manager.query('SELECT COUNT(*) AS c FROM counter_test');
      await new Promise((resolve) => setTimeout(resolve, 400));
      await manager.query('INSERT INTO counter_test (n) VALUES (1)');
    });
    await new Promise((resolve) => setTimeout(resolve, 100));
    await writer.query('INSERT INTO counter_test (n) VALUES (2)');

    await expect(readThenWrite).resolves.toBeUndefined();
    expect(await writer.query('SELECT n FROM counter_test ORDER BY n')).toEqual([{ n: 1 }, { n: 2 }]);
  });
});
