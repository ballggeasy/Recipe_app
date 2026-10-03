import { IsOptional, IsString, MaxLength } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.name)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.url)
  profileImageUrl?: string;
}
