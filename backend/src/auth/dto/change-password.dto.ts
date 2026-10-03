import { IsString, MaxLength, MinLength } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class ChangePasswordDto {
  @IsString()
  @MaxLength(LIMITS.password)
  currentPassword: string;

  @IsString()
  @MinLength(6)
  @MaxLength(LIMITS.password)
  newPassword: string;
}
