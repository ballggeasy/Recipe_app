import { IsIn, IsInt, IsISO8601, IsOptional, IsString, Min } from 'class-validator';
import { MealType } from '../meal-plan-entry.entity';

const MEAL_TYPES: MealType[] = ['breakfast', 'lunch', 'dinner', 'snack'];

export class CreateEntryDto {
  @IsString()
  recipeId: string;

  @IsISO8601()
  date: string;

  @IsIn(MEAL_TYPES)
  mealType: MealType;

  @IsOptional()
  @IsInt()
  @Min(1)
  servings?: number;
}
