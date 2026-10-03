import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Indexes for the lookups the API does on every request: reviews/comments of a recipe (newest
 * first), replies of a review, a user's meal plan and folders, and the recipe list order.
 * Names and columns must match the @Index decorators on the entities (migrations.spec.ts checks).
 */
export class AddLookupIndexes1790985700000 implements MigrationInterface {
  name = 'AddLookupIndexes1790985700000';

  private readonly indexes: Array<[name: string, table: string, columns: string[]]> = [
    ['IDX_reviews_recipe_created', 'reviews', ['recipeId', 'createdAt']],
    ['IDX_review_replies_review', 'review_replies', ['reviewId']],
    ['IDX_comments_recipe_created', 'comments', ['recipeId', 'createdAt']],
    ['IDX_meal_plan_user_date', 'meal_plan_entries', ['userId', 'date']],
    ['IDX_favorite_folders_user', 'favorite_folders', ['userId']],
    ['IDX_recipes_created', 'recipes', ['createdAt']],
    ['IDX_recipes_uploader', 'recipes', ['uploaderId']],
  ];

  public async up(queryRunner: QueryRunner): Promise<void> {
    for (const [name, table, columns] of this.indexes) {
      const cols = columns.map((c) => `"${c}"`).join(', ');
      await queryRunner.query(`CREATE INDEX IF NOT EXISTS "${name}" ON "${table}" (${cols})`);
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Dropping an index never loses data.
    for (const [name] of this.indexes) {
      await queryRunner.query(`DROP INDEX IF EXISTS "${name}"`);
    }
  }
}
