import { IsOptional, IsString, MaxLength } from 'class-validator';
import { LIMITS } from '../../common/limits';

// profileImageUrl is deliberately not accepted: the avatar only changes through POST /auth/avatar,
// so a client can't point it at an arbitrary URL or at another user's upload.
export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(LIMITS.name)
  name?: string;
}
