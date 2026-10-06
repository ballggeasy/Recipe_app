import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email: email.trim().toLowerCase() } });
  }

  findByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { googleId } });
  }

  findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  create(data: {
    email: string;
    passwordHash: string;
    name: string;
    googleId?: string;
    profileImageUrl?: string | null;
  }): Promise<User> {
    const user = this.usersRepository.create({
      email: data.email.trim().toLowerCase(),
      passwordHash: data.passwordHash,
      name: data.name.trim(),
      googleId: data.googleId ?? null,
      profileImageUrl: data.profileImageUrl ?? null,
    });
    return this.usersRepository.save(user);
  }

  async save(user: User): Promise<User> {
    return this.usersRepository.save(user);
  }

  async remove(user: User): Promise<void> {
    await this.usersRepository.remove(user);
  }
}
