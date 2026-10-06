import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Per-serving nutrition for the four official sample recipes that shipped without any, so the
 * recipe page shows it and the meal planner counts them. Worked out by hand from each recipe's
 * ingredient list and its 2 servings (same values as seed-data.ts, kept here as a snapshot).
 * Only fills recipes that still have no nutrition; anything set since is left alone.
 */
const NUTRITION: Array<[name: string, nutrition: Record<string, number>]> = [
  ['ทีรามิสุ', { calories: 1140, protein: 18, fat: 66, carbs: 116, sugar: 75, sodium: 180 }],
  ['ทาโคยากิ', { calories: 675, protein: 29, fat: 24, carbs: 81, sugar: 7, sodium: 1440 }],
  ['เกี๊ยวซ่าจีนนึ่ง', { calories: 530, protein: 26, fat: 24, carbs: 50, sugar: 2, sodium: 970 }],
  ['กิมจิจิเก', { calories: 550, protein: 21, fat: 48, carbs: 10, sugar: 3, sodium: 810 }],
];

export class AddOfficialRecipeNutrition1791400000000 implements MigrationInterface {
  name = 'AddOfficialRecipeNutrition1791400000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    for (const [name, nutrition] of NUTRITION) {
      await queryRunner.query(
        `UPDATE "recipes" SET "nutrition" = ? WHERE "name" = ? AND "isOfficial" = 1 AND "nutrition" IS NULL`,
        [JSON.stringify(nutrition), name],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    for (const [name, nutrition] of NUTRITION) {
      await queryRunner.query(
        `UPDATE "recipes" SET "nutrition" = NULL WHERE "name" = ? AND "isOfficial" = 1 AND "nutrition" = ?`,
        [name, JSON.stringify(nutrition)],
      );
    }
  }
}
