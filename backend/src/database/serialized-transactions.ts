import { DataSource, EntityManager } from 'typeorm';

/**
 * Runs top-level `manager.transaction()` calls on SQLite one at a time per DataSource (per process).
 *
 * TypeORM's SQLite driver keeps a single connection and a single query runner per DataSource, so
 * every request in a process shares them. When two requests call `transaction()` at the same moment,
 * both send BEGIN on that one connection: the second fails with "cannot start a transaction within a
 * transaction", and its ROLLBACK can undo the first request's writes. Five users posting a review at
 * once all got HTTP 500 before this.
 *
 * Nested calls (a transactional manager, which has its own `queryRunner`, starting another
 * transaction) pass straight through, otherwise they would wait for themselves. Other replicas are
 * separate processes with their own connection; BEGIN IMMEDIATE (immediate-transactions.ts) already
 * makes them take turns on the database file's write lock.
 *
 * TypeORM has no option for this either, so `EntityManager.transaction` is wrapped.
 */
const marker = Symbol.for('recipe.serializedTransactions');
const queues = new WeakMap<DataSource, Promise<unknown>>();

type TransactionFn = EntityManager['transaction'];

export function useSerializedTransactions(): void {
  const proto = EntityManager.prototype as EntityManager & { [marker]?: true };
  if (proto[marker]) return;

  const original = proto.transaction as (...args: unknown[]) => Promise<unknown>;
  proto.transaction = function (this: EntityManager, ...args: unknown[]) {
    if (this.queryRunner || this.connection.options.type !== 'sqlite') {
      return original.apply(this, args);
    }
    const previous = queues.get(this.connection) ?? Promise.resolve();
    const run = previous.then(() => original.apply(this, args));
    // The next transaction waits for this one whether it commits or fails.
    queues.set(
      this.connection,
      run.catch(() => undefined),
    );
    return run;
  } as TransactionFn;
  proto[marker] = true;
}
