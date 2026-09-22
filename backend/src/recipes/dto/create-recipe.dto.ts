import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { IngredientItem, NutritionInfo } from '../recipe.entity';

class IngredientItemDto implements IngredientItem {
  @IsString()
  name: string;

  @IsString()
  amount: string;

  @IsString()
  unit: string;
}

class NutritionInfoDto implements NutritionInfo {
  @IsNumber()
  calories: number;

  @IsNumber()
  protein: number;

  @IsNumber()
  fat: number;

  @IsNumber()
  carbs: number;

  @IsNumber()
  sugar: number;

  @IsNumber()
  sodium: number;
}

export class CreateRecipeDto {
  @IsString()
  name: string;

  @IsString()
  emoji: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUrls?: string[];

  @IsString()
  category: string;

  @IsString()
  country: string;

  @IsInt()
  @Min(0)
  cookTimeMinutes: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  prepTimeMinutes?: number;

  @IsString()
  difficulty: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  servings?: number;

  @IsArray()
  @IsString({ each: true })
  ingredients: string[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => IngredientItemDto)
  ingredientItems?: IngredientItemDto[];

  @IsArray()
  @IsString({ each: true })
  steps: string[];

  @IsOptional()
  @IsString()
  tips?: string;

  @IsOptional()
  @IsString()
  platingTips?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => NutritionInfoDto)
  nutrition?: NutritionInfoDto;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietTags?: string[];

  @IsOptional()
  @IsString()
  season?: string;

  @IsOptional()
  @IsString()
  videoUrl?: string;

  @IsOptional()
  @IsBoolean()
  isRecommended?: boolean;
}
