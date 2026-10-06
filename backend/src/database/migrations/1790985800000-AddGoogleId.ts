import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Sign in with Google: users get the Google account id (`sub`) they were linked to. Null for accounts
 * that only use a password. Unique, so one Google account can never sign in as two app users; SQLite
 * allows any number of nulls in a unique index.
 */
export class AddGoogleId1790985800000 implements MigrationInterface {
  name = 'AddGoogleId1790985800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    const columns: Array<{ name: string }> = await queryRunner.query(`PRAGMA table_info("users")`);
    if (!columns.some((column) => column.name === 'googleId')) {
      await queryRunner.query(`ALTER TABLE "users" ADD COLUMN "googleId" text`);
    }
    await queryRunner.query(`CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_google_id" ON "users" ("googleId")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_users_google_id"`);
    // SQLite 3.35+ can drop a column that is not indexed or referenced.
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "googleId"`);
  }
}
