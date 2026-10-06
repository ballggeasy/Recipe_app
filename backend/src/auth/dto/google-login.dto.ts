import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class GoogleLoginDto {
  /** The ID token (a JWT) the Google sign-in on the device returned. */
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  idToken: string;
}
