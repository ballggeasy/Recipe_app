import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { LIMITS } from '../../common/limits';
import { IngredientItem, NutritionInfo } from '../recipe.entity';

const MAX_MINUTES = 100_000;
const MAX_NUTRIENT = 100_000;

class IngredientItemDto implements IngredientItem {
  @IsString()
  @MaxLength(LIMITS.title)
  name: string;

  @IsString()
  @MaxLength(LIMITS.shortText)
  amount: string;

  @IsString()
  @MaxLength(LIMITS.shortText)
  unit: string;
}

class NutritionInfoDto implements NutritionInfo {
  @IsNumber()
  @Min(0)
  @Max(MAX_NUTRIENT)
  calories: number;

  @IsNumber()
  @Min(0)
  @Max(MAX_NUTRIENT)
  protein: number;

  @IsNumber()
  @Min(0)
  @Max(MAX_NUTRIENT)
  fat: number;

  @IsNumber()
  @Min(0)
  @Max(MAX_NUTRIENT)
  carbs: number;

  @IsNumber()
  @Min(0)
  @Max(MAX_NUTRIENT)
  sugar: number;

  @IsNumber()
  @Min(0)
  @Max(MAX_NUTRIENT)
  sodium: number;

  /** Sent back unchanged by the app when it saves a recipe whose values came from the AI estimate. */
  @IsOptional()
  @IsIn(['ai'])
  source?: 'ai';
}

export class CreateRecipeDto {
  @IsString()
  @MaxLength(LIMITS.title)
  name: string;

  @IsString()
  @MaxLength(LIMITS.emoji)
  emoji: string;

  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.url)
  imageUrl?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITS.imageUrls)
  @IsString({ each: true })
  @MaxLength(LIMITS.url, { each: true })
  imageUrls?: string[];

  @IsString()
  @MaxLength(LIMITS.shortText)
  category: string;

  @IsString()
  @MaxLength(LIMITS.shortText)
  country: string;

  @IsInt()
  @Min(0)
  @Max(MAX_MINUTES)
  cookTimeMinutes: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(MAX_MINUTES)
  prepTimeMinutes?: number;

  @IsString()
  @MaxLength(LIMITS.shortText)
  difficulty: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(1000)
  servings?: number;

  @IsArray()
  @ArrayMaxSize(LIMITS.listItems)
  @IsString({ each: true })
  @MaxLength(LIMITS.line, { each: true })
  ingredients: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITS.listItems)
  @ValidateNested({ each: true })
  @Type(() => IngredientItemDto)
  ingredientItems?: IngredientItemDto[];

  @IsArray()
  @ArrayMaxSize(LIMITS.listItems)
  @IsString({ each: true })
  @MaxLength(LIMITS.paragraph, { each: true })
  steps: string[];

  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.paragraph)
  tips?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.paragraph)
  platingTips?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => NutritionInfoDto)
  nutrition?: NutritionInfoDto;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITS.tags)
  @IsString({ each: true })
  @MaxLength(LIMITS.shortText, { each: true })
  dietTags?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.shortText)
  season?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.url)
  videoUrl?: string;
}
