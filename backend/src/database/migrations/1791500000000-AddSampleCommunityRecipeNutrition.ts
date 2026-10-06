import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Per-serving nutrition for the five sample "community" recipes from the seed (shown as shared by
 * made-up cooks, no uploader account), so every sample recipe has numbers for the meal planner.
 * Worked out by hand from each recipe's ingredients and its 2 servings, counting oil soaked up when
 * the steps deep-fry (same values as seed-data.ts, kept here as a snapshot). Only rows without an
 * uploader account and without nutrition are filled, so a real user's recipe is never touched.
 */
const NUTRITION: Array<[name: string, nutrition: Record<string, number>]> = [
  ['พิซซ่ามาร์เกอริต้า สูตรเตาฟืนบ้าน', { calories: 685, protein: 28, fat: 33, carbs: 68, sugar: 5, sodium: 1520 }],
  ['ข้าวหน้าปลาแซลมอน สไตล์บ้านฉัน', { calories: 420, protein: 22, fat: 11, carbs: 55, sugar: 1, sodium: 960 }],
  ['หมูผัดเปรี้ยวหวาน', { calories: 565, protein: 22, fat: 35, carbs: 40, sugar: 25, sodium: 310 }],
  ['ต๊อกบกกี เผ็ดนัวสูตรป้าซอ', { calories: 630, protein: 20, fat: 9, carbs: 116, sugar: 21, sodium: 1470 }],
  ['ไก่ทอดเกาหลีซอสยังนยอม', { calories: 915, protein: 39, fat: 49, carbs: 77, sugar: 22, sodium: 1690 }],
];

export class AddSampleCommunityRecipeNutrition1791500000000 implements MigrationInterface {
  name = 'AddSampleCommunityRecipeNutrition1791500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    for (const [name, nutrition] of NUTRITION) {
      await queryRunner.query(
        `UPDATE "recipes" SET "nutrition" = ? WHERE "name" = ? AND "uploaderId" IS NULL AND "nutrition" IS NULL`,
        [JSON.stringify(nutrition), name],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    for (const [name, nutrition] of NUTRITION) {
      await queryRunner.query(
        `UPDATE "recipes" SET "nutrition" = NULL WHERE "name" = ? AND "uploaderId" IS NULL AND "nutrition" = ?`,
        [name, JSON.stringify(nutrition)],
      );
    }
  }
}
