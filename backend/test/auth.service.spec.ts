import { BadRequestException, ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { AuthService } from '../src/auth/auth.service';
import { User } from '../src/users/user.entity';
import { ResetStatePatch, UsersService } from '../src/users/users.service';

/** In-memory stand-in for UsersService so AuthService logic runs without a database. */
function createUsersServiceFake() {
  const users = new Map<string, User>();
  let nextId = 1;
  return {
    users,
    findByEmail: jest.fn(async (email: string) =>
      [...users.values()].find((u) => u.email === email.trim().toLowerCase()) ?? null,
    ),
    findById: jest.fn(async (id: string) => users.get(id) ?? null),
    create: jest.fn(async (data: { email: string; passwordHash: string; name: string }) => {
      const user = {
        id: `user-${nextId++}`,
        email: data.email.trim().toLowerCase(),
        passwordHash: data.passwordHash,
        name: data.name.trim(),
        profileImageUrl: null,
        createdAt: new Date(),
      } as User;
      users.set(user.id, user);
      return user;
    }),
    save: jest.fn(async (user: User) => {
      users.set(user.id, user);
      return user;
    }),
    updateResetState: jest.fn(async (id: string, patch: ResetStatePatch) => {
      Object.assign(users.get(id)!, patch);
    }),
    consumeResetAttempt: jest.fn(async (id: string, max: number) => {
      const user = users.get(id)!;
      if (user.resetCodeAttempts >= max) return false;
      user.resetCodeAttempts += 1;
      return true;
    }),
    remove: jest.fn(async (user: User) => {
      users.delete(user.id);
    }),
  };
}

describe('AuthService', () => {
  let service: AuthService;
  let jwtService: JwtService;
  let usersService: ReturnType<typeof createUsersServiceFake>;

  beforeEach(async () => {
    usersService = createUsersServiceFake();
    const moduleRef = await Test.createTestingModule({
      imports: [JwtModule.register({ secret: 'test-secret', signOptions: { expiresIn: '1h' } })],
      providers: [AuthService, { provide: UsersService, useValue: usersService }],
    }).compile();

    service = moduleRef.get(AuthService);
    jwtService = moduleRef.get(JwtService);
  });

  describe('register', () => {
    it('normalizes the email, hashes the password and returns a signed token', async () => {
      const result = await service.register('Somchai', '  Somchai@Example.COM ', 'secret123');

      expect(result.user).toEqual({
        id: 'user-1',
        email: 'somchai@example.com',
        name: 'Somchai',
        profileImageUrl: null,
      });
      expect(result.user).not.toHaveProperty('passwordHash');

      const stored = usersService.users.get('user-1')!;
      expect(stored.passwordHash).not.toBe('secret123');
      await expect(bcrypt.compare('secret123', stored.passwordHash)).resolves.toBe(true);

      const payload = jwtService.verify(result.accessToken);
      expect(payload).toMatchObject({ sub: 'user-1', email: 'somchai@example.com' });
    });

    it('rejects an email that is already registered', async () => {
      await service.register('A', 'a@example.com', 'secret123');
      await expect(service.register('B', 'A@example.com', 'secret456')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('login', () => {
    beforeEach(async () => {
      await service.register('Somchai', 'somchai@example.com', 'secret123');
    });

    it('returns a token for valid credentials regardless of email casing', async () => {
      const result = await service.login('SOMCHAI@example.com', 'secret123');
      expect(result.user.email).toBe('somchai@example.com');
      expect(jwtService.verify(result.accessToken).sub).toBe(result.user.id);
    });

    it('answers an unknown email and a wrong password the same way', async () => {
      const unknown = await service.login('nobody@example.com', 'secret123').catch((e: unknown) => e);
      const wrong = await service.login('somchai@example.com', 'wrong-pass').catch((e: unknown) => e);

      expect(unknown).toBeInstanceOf(UnauthorizedException);
      expect(wrong).toBeInstanceOf(UnauthorizedException);
      expect((unknown as Error).message).toBe((wrong as Error).message);
    });
  });

  describe('changePassword', () => {
    let user: User;

    beforeEach(async () => {
      const { user: safe } = await service.register('Somchai', 'somchai@example.com', 'secret123');
      user = usersService.users.get(safe.id)!;
    });

    it('rejects a wrong current password and keeps the old one', async () => {
      const oldHash = user.passwordHash;
      await expect(service.changePassword(user, 'wrong-pass', 'newpass123')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(usersService.users.get(user.id)!.passwordHash).toBe(oldHash);
    });

    it('lets the user log in with the new password afterwards', async () => {
      await service.changePassword(user, 'secret123', 'newpass123');

      await expect(service.login('somchai@example.com', 'newpass123')).resolves.toBeDefined();
      await expect(service.login('somchai@example.com', 'secret123')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });

  describe('updateProfile', () => {
    it('trims the new name and leaves fields that were not sent untouched', async () => {
      const { user: safe } = await service.register('Somchai', 'somchai@example.com', 'secret123');
      const user = usersService.users.get(safe.id)!;

      const updated = await service.updateProfile(user, '  Somsri  ');

      expect(updated.name).toBe('Somsri');
      expect(updated.profileImageUrl).toBeNull();
    });
  });

  describe('password reset', () => {
    beforeEach(async () => {
      await service.register('Somchai', 'somchai@example.com', 'secret123');
    });

    it('sets the new password only with the code that was issued, then invalidates the code', async () => {
      const code = (await service.requestPasswordReset('SOMCHAI@example.com'))!;
      expect(code).toMatch(/^\d{6}$/);

      await service.resetPassword('somchai@example.com', code, 'newpass123');

      await expect(service.login('somchai@example.com', 'newpass123')).resolves.toBeDefined();
      await expect(service.resetPassword('somchai@example.com', code, 'again123')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects a reset without a pending code', async () => {
      await expect(service.resetPassword('somchai@example.com', '123456', 'newpass123')).rejects.toBeInstanceOf(
        BadRequestException,
      );
      await expect(service.login('somchai@example.com', 'secret123')).resolves.toBeDefined();
    });

    it('rejects a wrong code and locks the code after 5 failed attempts', async () => {
      const code = (await service.requestPasswordReset('somchai@example.com'))!;
      const wrong = code === '000000' ? '111111' : '000000';

      for (let i = 0; i < 5; i++) {
        await expect(service.resetPassword('somchai@example.com', wrong, 'newpass123')).rejects.toBeInstanceOf(
          BadRequestException,
        );
      }
      await expect(service.resetPassword('somchai@example.com', code, 'newpass123')).rejects.toBeInstanceOf(
        BadRequestException,
      );
      await expect(service.login('somchai@example.com', 'secret123')).resolves.toBeDefined();
    });

    it('keeps counting failed attempts when a new code is requested in the same window', async () => {
      const first = (await service.requestPasswordReset('somchai@example.com'))!;
      const wrong = (c: string) => (c === '000000' ? '111111' : '000000');

      for (let i = 0; i < 3; i++) {
        await expect(service.resetPassword('somchai@example.com', wrong(first), 'x123456')).rejects.toBeInstanceOf(
          BadRequestException,
        );
      }
      const second = (await service.requestPasswordReset('somchai@example.com'))!;
      for (let i = 0; i < 2; i++) {
        await expect(service.resetPassword('somchai@example.com', wrong(second), 'x123456')).rejects.toBeInstanceOf(
          BadRequestException,
        );
      }

      // ครบ 5 ครั้งในช่วงเดียวกันแล้ว — รหัสที่ถูกก็ใช้ไม่ได้ และขอรหัสใหม่ไม่ได้จนกว่าช่วงจะหมด
      await expect(service.resetPassword('somchai@example.com', second, 'newpass123')).rejects.toBeInstanceOf(
        BadRequestException,
      );
      await expect(service.requestPasswordReset('somchai@example.com')).resolves.toBeNull();
    });

    it('starts a fresh window with a new attempt budget once the old one has expired', async () => {
      await service.requestPasswordReset('somchai@example.com');
      const user = [...usersService.users.values()][0];
      user.resetCodeAttempts = 5;
      user.resetCodeExpiresAt = new Date(Date.now() - 1000);

      const code = (await service.requestPasswordReset('somchai@example.com'))!;
      await expect(service.resetPassword('somchai@example.com', code, 'newpass123')).resolves.toBeUndefined();
    });

    it('rejects an expired code', async () => {
      const code = (await service.requestPasswordReset('somchai@example.com'))!;
      const user = [...usersService.users.values()][0];
      user.resetCodeExpiresAt = new Date(Date.now() - 1000);

      await expect(service.resetPassword('somchai@example.com', code, 'newpass123')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('returns null for an unknown email without creating anything', async () => {
      await expect(service.requestPasswordReset('nobody@example.com')).resolves.toBeNull();
    });
  });

  describe('deleteAccount', () => {
    it('removes the user', async () => {
      const { user: safe } = await service.register('Somchai', 'somchai@example.com', 'secret123');
      await service.deleteAccount(usersService.users.get(safe.id)!);
      expect(usersService.users.has(safe.id)).toBe(false);
    });
  });
});
