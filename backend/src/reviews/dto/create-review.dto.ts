import { ArrayMaxSize, IsArray, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class CreateReviewDto {
  @IsNumber()
  @Min(0)
  @Max(5)
  rating: number;

  @IsString()
  @MaxLength(LIMITS.longText)
  content: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITS.imageUrls)
  @IsString({ each: true })
  @MaxLength(LIMITS.url, { each: true })
  imageUrls?: string[];
}
