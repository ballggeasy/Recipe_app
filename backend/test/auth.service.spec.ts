import { BadRequestException, ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { AuthService } from '../src/auth/auth.service';
import { GoogleIdentity, GoogleTokenVerifier } from '../src/auth/google-token-verifier';
import { User } from '../src/users/user.entity';
import { UsersService } from '../src/users/users.service';

/** In-memory stand-in for UsersService so AuthService logic runs without a database. */
function createUsersServiceFake() {
  const users = new Map<string, User>();
  let nextId = 1;
  return {
    users,
    findByEmail: jest.fn(
      async (email: string) => [...users.values()].find((u) => u.email === email.trim().toLowerCase()) ?? null,
    ),
    findByGoogleId: jest.fn(
      async (googleId: string) => [...users.values()].find((u) => u.googleId === googleId) ?? null,
    ),
    findById: jest.fn(async (id: string) => users.get(id) ?? null),
    create: jest.fn(
      async (data: {
        email: string;
        passwordHash: string;
        name: string;
        googleId?: string;
        profileImageUrl?: string | null;
      }) => {
        const user = {
          id: `user-${nextId++}`,
          email: data.email.trim().toLowerCase(),
          passwordHash: data.passwordHash,
          name: data.name.trim(),
          googleId: data.googleId ?? null,
          profileImageUrl: data.profileImageUrl ?? null,
          createdAt: new Date(),
        } as User;
        users.set(user.id, user);
        return user;
      },
    ),
    save: jest.fn(async (user: User) => {
      users.set(user.id, user);
      return user;
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
  let googleVerifier: { verify: jest.Mock<Promise<GoogleIdentity>, [string]> };

  beforeEach(async () => {
    usersService = createUsersServiceFake();
    googleVerifier = { verify: jest.fn() };
    const moduleRef = await Test.createTestingModule({
      imports: [JwtModule.register({ secret: 'test-secret', signOptions: { expiresIn: '1h' } })],
      providers: [
        AuthService,
        { provide: UsersService, useValue: usersService },
        { provide: GoogleTokenVerifier, useValue: googleVerifier },
      ],
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
      await expect(service.register('B', 'A@example.com', 'secret456')).rejects.toBeInstanceOf(ConflictException);
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

    it('throws UnauthorizedException for a wrong password', async () => {
      await expect(service.login('somchai@example.com', 'wrong-pass')).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('answers an unknown email exactly like a wrong password so emails cannot be enumerated', async () => {
      const unknown = await service.login('nobody@example.com', 'secret123').catch((e) => e);
      const wrong = await service.login('somchai@example.com', 'wrong-pass').catch((e) => e);

      expect(unknown).toBeInstanceOf(UnauthorizedException);
      expect(unknown.getStatus()).toBe(wrong.getStatus());
      expect(unknown.getResponse()).toEqual(wrong.getResponse());
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
        BadRequestException,
      );
      expect(usersService.users.get(user.id)!.passwordHash).toBe(oldHash);
    });

    it('lets the user log in with the new password afterwards', async () => {
      await service.changePassword(user, 'secret123', 'newpass123');

      await expect(service.login('somchai@example.com', 'newpass123')).resolves.toBeDefined();
      await expect(service.login('somchai@example.com', 'secret123')).rejects.toBeInstanceOf(UnauthorizedException);
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

  describe('deleteAccount', () => {
    it('removes the user', async () => {
      const { user: safe } = await service.register('Somchai', 'somchai@example.com', 'secret123');
      await service.deleteAccount(usersService.users.get(safe.id)!);
      expect(usersService.users.has(safe.id)).toBe(false);
    });
  });

  describe('loginWithGoogle', () => {
    const identity: GoogleIdentity = {
      googleId: 'google-123',
      email: 'somchai@example.com',
      name: 'Somchai G',
      picture: 'https://lh3.googleusercontent.com/a/photo',
    };

    it('creates an account for a new Google user, with a password nobody knows', async () => {
      googleVerifier.verify.mockResolvedValue(identity);

      const result = await service.loginWithGoogle('id-token');

      expect(googleVerifier.verify).toHaveBeenCalledWith('id-token');
      expect(result.user).toEqual({
        id: 'user-1',
        email: 'somchai@example.com',
        name: 'Somchai G',
        profileImageUrl: 'https://lh3.googleusercontent.com/a/photo',
      });
      expect(jwtService.verify(result.accessToken)).toMatchObject({ sub: 'user-1' });
      expect(usersService.users.get('user-1')!.googleId).toBe('google-123');
      // No password can log in to it: /auth/login answers the same 401 as for a wrong password.
      await expect(service.login('somchai@example.com', 'anything')).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('falls back to the part of the email before the @ when Google sends no name', async () => {
      googleVerifier.verify.mockResolvedValue({ ...identity, name: null, picture: null });

      const result = await service.loginWithGoogle('id-token');

      expect(result.user.name).toBe('somchai');
      expect(result.user.profileImageUrl).toBeNull();
    });

    it('links the Google account to the user who registered with the same email', async () => {
      const { user: registered } = await service.register('Somchai', 'somchai@example.com', 'secret123');
      googleVerifier.verify.mockResolvedValue(identity);

      const result = await service.loginWithGoogle('id-token');

      expect(result.user.id).toBe(registered.id);
      expect(usersService.users.size).toBe(1);
      const stored = usersService.users.get(registered.id)!;
      expect(stored.googleId).toBe('google-123');
      expect(stored.name).toBe('Somchai'); // keeps the name they chose
      expect(stored.profileImageUrl).toBe('https://lh3.googleusercontent.com/a/photo');
      // The password still works.
      await expect(service.login('somchai@example.com', 'secret123')).resolves.toMatchObject({
        user: { id: registered.id },
      });
    });

    it('keeps a profile picture the user already has', async () => {
      const { user: registered } = await service.register('Somchai', 'somchai@example.com', 'secret123');
      usersService.users.get(registered.id)!.profileImageUrl = '/uploads/avatars/mine.jpg';
      googleVerifier.verify.mockResolvedValue(identity);

      const result = await service.loginWithGoogle('id-token');

      expect(result.user.profileImageUrl).toBe('/uploads/avatars/mine.jpg');
    });

    it('signs the same user in again by Google id, even after the email changed', async () => {
      googleVerifier.verify.mockResolvedValue(identity);
      const first = await service.loginWithGoogle('id-token');
      googleVerifier.verify.mockResolvedValue({ ...identity, email: 'new-address@example.com' });

      const second = await service.loginWithGoogle('id-token');

      expect(second.user.id).toBe(first.user.id);
      expect(usersService.users.size).toBe(1);
    });

    it('does not touch the database when the token is refused', async () => {
      googleVerifier.verify.mockRejectedValue(new UnauthorizedException('ยืนยันตัวตนกับ Google ไม่สำเร็จ'));

      await expect(service.loginWithGoogle('forged')).rejects.toBeInstanceOf(UnauthorizedException);
      expect(usersService.create).not.toHaveBeenCalled();
      expect(usersService.save).not.toHaveBeenCalled();
    });
  });
});
