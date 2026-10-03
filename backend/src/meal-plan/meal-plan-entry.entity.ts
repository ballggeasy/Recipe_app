import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';

@Index('IDX_meal_plan_user_date', ['userId', 'date'])
@Entity('meal_plan_entries')
export class MealPlanEntry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  recipeId: string;

  @Column({ type: 'datetime' })
  date: Date;

  @Column({ type: 'text' })
  mealType: MealType;

  @Column({ default: 1 })
  servings: number;

  @CreateDateColumn()
  createdAt: Date;
}
