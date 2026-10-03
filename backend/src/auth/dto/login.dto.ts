import { IsBoolean, IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class LoginDto {
  @IsEmail()
  @MaxLength(LIMITS.email)
  email: string;

  @IsString()
  @MaxLength(LIMITS.password)
  password: string;

  @IsOptional()
  @IsBoolean()
  remember?: boolean;
}
