import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class RegisterDto {
  @IsString()
  @MinLength(1)
  @MaxLength(LIMITS.name)
  name: string;

  @IsEmail()
  @MaxLength(LIMITS.email)
  email: string;

  @IsString()
  @MinLength(6)
  @MaxLength(LIMITS.password)
  password: string;
}
