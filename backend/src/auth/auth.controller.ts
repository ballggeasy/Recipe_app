import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { imageUploadOptions, uploadedFileUrl } from '../common/image-upload';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { CurrentUser } from './current-user.decorator';
import { User } from '../users/user.entity';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto.name, dto.email, dto.password);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto.email, dto.password);
  }

  /** ขอรหัสยืนยันสำหรับตั้งรหัสผ่านใหม่ — ตอบเหมือนกันเสมอ ไม่บอกว่ามีบัญชีนี้หรือไม่ */
  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    await this.authService.requestPasswordReset(dto.email);
    return { success: true };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() dto: ResetPasswordDto) {
    await this.authService.resetPassword(dto.email, dto.code, dto.newPassword);
    return { success: true };
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@CurrentUser() user: User) {
    return this.authService.toSafeUser(user);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  updateProfile(@CurrentUser() user: User, @Body() dto: UpdateProfileDto) {
    return this.authService.updateProfile(user, dto.name);
  }

  @UseGuards(JwtAuthGuard)
  @Post('avatar')
  @UseInterceptors(
    FileInterceptor(
      'file',
      imageUploadOptions('avatars', (req) => (req as unknown as { user: User }).user.id),
    ),
  )
  uploadAvatar(@CurrentUser() user: User, @UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('ไม่พบไฟล์รูปภาพ');
    }
    return this.authService.updateAvatar(user, uploadedFileUrl('avatars', file.filename));
  }

  @UseGuards(JwtAuthGuard)
  @Post('change-password')
  @HttpCode(HttpStatus.OK)
  async changePassword(@CurrentUser() user: User, @Body() dto: ChangePasswordDto) {
    await this.authService.changePassword(user, dto.currentPassword, dto.newPassword);
    return { success: true };
  }

  @UseGuards(JwtAuthGuard)
  @Delete('account')
  @HttpCode(HttpStatus.OK)
  async deleteAccount(@CurrentUser() user: User) {
    await this.authService.deleteAccount(user);
    return { success: true };
  }
}
