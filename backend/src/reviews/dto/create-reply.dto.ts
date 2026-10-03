import { IsString, MaxLength } from 'class-validator';
import { LIMITS } from '../../common/limits';

export class CreateReplyDto {
  @IsString()
  @MaxLength(LIMITS.paragraph)
  content: string;
}
