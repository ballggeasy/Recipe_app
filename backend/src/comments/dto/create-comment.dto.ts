import { IsArray, IsOptional, IsString, MaxLength, ArrayMaxSize } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class CreateCommentDto {
  @IsString()
  @MaxLength(LIMITS.paragraph)
  content: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  parentId?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(LIMITS.tags)
  @IsString({ each: true })
  @MaxLength(LIMITS.shortText, { each: true })
  mentions?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.url)
  imageUrl?: string;
}
