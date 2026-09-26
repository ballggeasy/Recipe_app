import { ConflictException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { AuthService } from '../src/auth/auth.service';
import { User } from '../src/users/user.entity';
import { UsersService } from '../src/users/users.service';

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

    it('throws NotFoundException for an unknown email', async () => {
      await expect(service.login('nobody@example.com', 'secret123')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('throws UnauthorizedException for a wrong password', async () => {
      await expect(service.login('somchai@example.com', 'wrong-pass')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
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

  describe('deleteAccount', () => {
    it('removes the user', async () => {
      const { user: safe } = await service.register('Somchai', 'somchai@example.com', 'secret123');
      await service.deleteAccount(usersService.users.get(safe.id)!);
      expect(usersService.users.has(safe.id)).toBe(false);
    });
  });
});
