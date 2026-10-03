import { IsOptional, IsString, MaxLength } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class CreateFolderDto {
  @IsString()
  @MaxLength(LIMITS.name)
  name: string;

  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.emoji)
  emoji?: string;
}
