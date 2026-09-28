import { IsOptional, IsString, MinLength } from 'class-validator';

/** รูปโปรไฟล์เปลี่ยนได้ทาง POST /auth/avatar เท่านั้น — client กำหนด profileImageUrl เองไม่ได้ */
export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  name?: string;
}
