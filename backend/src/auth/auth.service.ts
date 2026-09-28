import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { randomInt } from 'crypto';
import { removeUploadedFile } from '../common/image-upload';
import { User } from '../users/user.entity';
import { ResetStatePatch, UsersService } from '../users/users.service';

// ช่วงเวลารีเซ็ต 15 นาที เดารหัสได้รวม 5 ครั้งต่อช่วง ไม่ว่าจะขอรหัสใหม่กี่ครั้ง
const RESET_WINDOW_MS = 15 * 60 * 1000;
const RESET_CODE_MAX_ATTEMPTS = 5;

// ใช้เทียบรหัสผ่านเมื่อไม่พบอีเมล ให้เวลาตอบใกล้เคียงกรณีรหัสผิด (ไม่งั้นวัดเวลาแล้วรู้ว่าอีเมลไหนมีบัญชี)
const DUMMY_PASSWORD_HASH = bcrypt.hashSync('dummy-password-for-timing', 10);

export interface AuthResult {
  accessToken: string;
  user: SafeUser;
}

export interface SafeUser {
  id: string;
  email: string;
  name: string;
  profileImageUrl: string | null;
}

function toSafeUser(user: User): SafeUser {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    profileImageUrl: user.profileImageUrl,
  };
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  private hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, 10);
  }

  private signToken(user: User): string {
    return this.jwtService.sign({ sub: user.id, email: user.email });
  }

  async register(name: string, email: string, password: string): Promise<AuthResult> {
    const normalizedEmail = email.trim().toLowerCase();
    const existing = await this.usersService.findByEmail(normalizedEmail);
    if (existing) {
      throw new ConflictException('อีเมลนี้ถูกใช้งานแล้ว');
    }

    const passwordHash = await this.hashPassword(password);
    const user = await this.usersService.create({ email: normalizedEmail, passwordHash, name });

    return { accessToken: this.signToken(user), user: toSafeUser(user) };
  }

  async login(email: string, password: string): Promise<AuthResult> {
    const normalizedEmail = email.trim().toLowerCase();
    const user = await this.usersService.findByEmail(normalizedEmail);
    // ข้อความเดียวกันทั้งกรณีไม่มีบัญชีและรหัสผิด เพื่อไม่ให้ใช้หน้า login ไล่เช็คว่าอีเมลไหนมีบัญชี
    const passwordMatches = await bcrypt.compare(password, user?.passwordHash ?? DUMMY_PASSWORD_HASH);
    if (!user || !passwordMatches) {
      throw new UnauthorizedException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }

    return { accessToken: this.signToken(user), user: toSafeUser(user) };
  }

  /**
   * สร้างรหัสยืนยัน 6 หลักสำหรับตั้งรหัสผ่านใหม่ — ยังไม่มีระบบส่งอีเมล จึงเขียนรหัสลง log ของ server แทน
   * รหัสใหม่ที่ขอภายในช่วงเดิมจะแทนรหัสเก่าแต่ไม่ต่ออายุช่วงและไม่ล้างจำนวนครั้งที่เดาผิด
   * (ไม่งั้นจะวนขอรหัสใหม่เพื่อเดาต่อได้เรื่อย ๆ); เดาครบ 5 ครั้งแล้วต้องรอให้ช่วงหมดก่อน
   * คืนรหัสให้ผู้เรียกภายใน (เช่น test) เท่านั้น ห้ามส่งกลับไปใน HTTP response; คืน null ถ้าไม่ได้ออกรหัส
   */
  async requestPasswordReset(email: string): Promise<string | null> {
    const user = await this.usersService.findByEmail(email);
    if (!user) return null;

    const now = Date.now();
    const windowActive = !!user.resetCodeExpiresAt && user.resetCodeExpiresAt.getTime() > now;
    if (windowActive && user.resetCodeAttempts >= RESET_CODE_MAX_ATTEMPTS) return null;

    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    const patch: ResetStatePatch = { resetCodeHash: await bcrypt.hash(code, 10) };
    if (!windowActive) {
      patch.resetCodeExpiresAt = new Date(now + RESET_WINDOW_MS);
      patch.resetCodeAttempts = 0;
    }
    await this.usersService.updateResetState(user.id, patch);

    const expiresAt = patch.resetCodeExpiresAt ?? user.resetCodeExpiresAt!;
    this.logger.log(`รหัสยืนยันสำหรับตั้งรหัสผ่านใหม่ของ ${user.email}: ${code} (ใช้ได้ถึง ${expiresAt.toISOString()})`);
    return code;
  }

  async resetPassword(email: string, code: string, newPassword: string): Promise<void> {
    const invalid = new BadRequestException('รหัสยืนยันไม่ถูกต้องหรือหมดอายุแล้ว');
    const user = await this.usersService.findByEmail(email);
    if (
      !user ||
      !user.resetCodeHash ||
      !user.resetCodeExpiresAt ||
      user.resetCodeExpiresAt.getTime() < Date.now() ||
      !(await this.usersService.consumeResetAttempt(user.id, RESET_CODE_MAX_ATTEMPTS)) ||
      !(await bcrypt.compare(code, user.resetCodeHash))
    ) {
      throw invalid;
    }

    user.passwordHash = await this.hashPassword(newPassword);
    user.resetCodeHash = null;
    user.resetCodeExpiresAt = null;
    user.resetCodeAttempts = 0;
    await this.usersService.save(user);
  }

  async changePassword(user: User, currentPassword: string, newPassword: string): Promise<void> {
    const passwordMatches = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!passwordMatches) {
      throw new UnauthorizedException('รหัสผ่านปัจจุบันไม่ถูกต้อง');
    }
    user.passwordHash = await this.hashPassword(newPassword);
    await this.usersService.save(user);
  }

  async updateProfile(user: User, name?: string): Promise<SafeUser> {
    if (name !== undefined) user.name = name.trim();
    const saved = await this.usersService.save(user);
    return toSafeUser(saved);
  }

  async updateAvatar(user: User, relativePath: string): Promise<SafeUser> {
    const previous = user.profileImageUrl;
    user.profileImageUrl = relativePath;
    const saved = await this.usersService.save(user);

    if (previous && previous.startsWith('/uploads/')) {
      void removeUploadedFile(previous);
    }

    return toSafeUser(saved);
  }

  async deleteAccount(user: User): Promise<void> {
    await this.usersService.remove(user);
  }

  toSafeUser(user: User): SafeUser {
    return toSafeUser(user);
  }
}
