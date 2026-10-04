import { SqliteQueryRunner } from 'typeorm/driver/sqlite/SqliteQueryRunner';

/**
 * Makes every TypeORM transaction on SQLite start with `BEGIN IMMEDIATE`.
 *
 * TypeORM opens transactions with a plain `BEGIN` (deferred) and `save()` then reads the existing
 * row before it writes. When another process (a second backend replica) commits in between, the
 * reader's snapshot is stale and SQLite refuses the write at once with SQLITE_BUSY: the busy timeout
 * does not apply, because waiting could never succeed. Taking the write lock when the transaction
 * starts makes the transaction wait for it (up to the busy timeout) instead.
 *
 * TypeORM has no option for this on its sqlite driver, so the one statement it sends is swapped.
 * test/concurrency.spec.ts fails if a TypeORM upgrade changes that statement.
 */
const PLAIN_BEGIN = 'BEGIN TRANSACTION';
const IMMEDIATE_BEGIN = 'BEGIN IMMEDIATE TRANSACTION';

type QueryFn = SqliteQueryRunner['query'];
const marker = Symbol.for('recipe.immediateTransactions');

export function useImmediateTransactions(): void {
  const proto = SqliteQueryRunner.prototype as SqliteQueryRunner & { [marker]?: true };
  if (proto[marker]) return;

  const original: QueryFn = proto.query;
  proto.query = function (this: SqliteQueryRunner, query: string, ...rest: unknown[]) {
    const sql = query === PLAIN_BEGIN ? IMMEDIATE_BEGIN : query;
    return (original as (...args: unknown[]) => Promise<unknown>).call(this, sql, ...rest);
  } as QueryFn;
  proto[marker] = true;
}
