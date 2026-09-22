import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

export interface IngredientItem {
  name: string;
  amount: string;
  unit: string;
}

export interface NutritionInfo {
  calories: number;
  protein: number;
  fat: number;
  carbs: number;
  sugar: number;
  sodium: number;
}

@Entity('recipes')
export class Recipe {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column()
  emoji: string;

  @Column({ default: '' })
  imageUrl: string;

  @Column({ type: 'simple-json', default: '[]' })
  imageUrls: string[];

  @Column()
  category: string;

  @Column()
  country: string;

  @Column()
  cookTimeMinutes: number;

  @Column({ default: 10 })
  prepTimeMinutes: number;

  @Column()
  difficulty: string;

  @Column({ default: 2 })
  servings: number;

  @Column({ type: 'simple-json', default: '[]' })
  ingredients: string[];

  @Column({ type: 'simple-json', default: '[]' })
  ingredientItems: IngredientItem[];

  @Column({ type: 'simple-json', default: '[]' })
  steps: string[];

  @Column({ type: 'text', nullable: true })
  tips: string | null;

  @Column({ type: 'text', nullable: true })
  platingTips: string | null;

  @Column({ type: 'simple-json', nullable: true })
  nutrition: NutritionInfo | null;

  @Column({ type: 'simple-json', default: '[]' })
  dietTags: string[];

  @Column({ default: 'ตลอดปี' })
  season: string;

  @Column({ type: 'text', nullable: true })
  videoUrl: string | null;

  @Column({ default: true })
  isOfficial: boolean;

  @Column({ type: 'text', nullable: true })
  uploaderId: string | null;

  @Column({ type: 'text', nullable: true })
  uploaderName: string | null;

  @Column({ type: 'float', default: 0 })
  rating: number;

  @Column({ default: 0 })
  reviewCount: number;

  @Column({ default: 0 })
  viewCount: number;

  @Column({ default: false })
  isRecommended: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
