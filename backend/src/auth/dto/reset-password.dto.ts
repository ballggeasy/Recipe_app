import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class ResetPasswordDto {
  @IsEmail()
  @MaxLength(LIMITS.email)
  email: string;

  @IsString()
  @MinLength(6)
  @MaxLength(LIMITS.password)
  newPassword: string;
}
