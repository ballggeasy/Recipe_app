import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import { imageUploadOptions, uploadedFileUrl } from '../common/image-upload';
import { AUTH_RATE_LIMIT } from '../common/rate-limit';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleLoginDto } from './dto/google-login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { PasswordResetEnabledGuard } from './password-reset-enabled.guard';
import { CurrentUser } from './current-user.decorator';
import { User } from '../users/user.entity';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Throttle(AUTH_RATE_LIMIT)
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto.name, dto.email, dto.password);
  }

  @Throttle(AUTH_RATE_LIMIT)
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto.email, dto.password);
  }

  /** Sign in (or sign up) with the ID token the Google sign-in on the device returned. */
  @Throttle(AUTH_RATE_LIMIT)
  @Post('google')
  @HttpCode(HttpStatus.OK)
  googleLogin(@Body() dto: GoogleLoginDto) {
    return this.authService.loginWithGoogle(dto.idToken);
  }

  // Both endpoints below are off unless ALLOW_INSECURE_PASSWORD_RESET=true (see the guard).
  @Throttle(AUTH_RATE_LIMIT)
  @UseGuards(PasswordResetEnabledGuard)
  @Get('exists/:email')
  async exists(@Param('email') email: string) {
    const exists = await this.authService.checkUserExists(email);
    return { exists };
  }

  @Throttle(AUTH_RATE_LIMIT)
  @UseGuards(PasswordResetEnabledGuard)
  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() dto: ResetPasswordDto) {
    await this.authService.resetPassword(dto.email, dto.newPassword);
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
    return this.authService.updateProfile(user, dto.name, dto.profileImageUrl);
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

  @Throttle(AUTH_RATE_LIMIT)
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
