import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { removeUploadedFile } from '../common/image-upload';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';

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

const INVALID_CREDENTIALS_MESSAGE = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
const BCRYPT_COST = 10;
/** Compared against when the email is unknown so login takes as long as for a real account. */
const DUMMY_PASSWORD_HASH = bcrypt.hashSync('not-a-real-password', BCRYPT_COST);

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
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  private hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, BCRYPT_COST);
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

    // Same work and same answer for "no such account" and "wrong password", so the response
    // (status, body, timing) can't be used to find out which emails are registered.
    const passwordMatches = await bcrypt.compare(password, user?.passwordHash ?? DUMMY_PASSWORD_HASH);
    if (!user || !passwordMatches) {
      throw new UnauthorizedException(INVALID_CREDENTIALS_MESSAGE);
    }

    return { accessToken: this.signToken(user), user: toSafeUser(user) };
  }

  async checkUserExists(email: string): Promise<boolean> {
    const user = await this.usersService.findByEmail(email);
    return !!user;
  }

  async resetPassword(email: string, newPassword: string): Promise<void> {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new NotFoundException('ไม่พบบัญชีผู้ใช้นี้');
    }
    user.passwordHash = await this.hashPassword(newPassword);
    await this.usersService.save(user);
  }

  async changePassword(user: User, currentPassword: string, newPassword: string): Promise<void> {
    const passwordMatches = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!passwordMatches) {
      // 400, not 401: a wrong form field must not look like an expired session (the app logs out on 401).
      throw new BadRequestException('รหัสผ่านปัจจุบันไม่ถูกต้อง');
    }
    user.passwordHash = await this.hashPassword(newPassword);
    await this.usersService.save(user);
  }

  async updateProfile(user: User, name?: string, profileImageUrl?: string): Promise<SafeUser> {
    if (name !== undefined) user.name = name.trim();
    if (profileImageUrl !== undefined) user.profileImageUrl = profileImageUrl;
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
