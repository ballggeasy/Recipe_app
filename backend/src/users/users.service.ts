import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

export type ResetStatePatch = Partial<Pick<User, 'resetCodeHash' | 'resetCodeExpiresAt' | 'resetCodeAttempts'>>;

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email: email.trim().toLowerCase() } });
  }

  findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  create(data: { email: string; passwordHash: string; name: string }): Promise<User> {
    const user = this.usersRepository.create({
      email: data.email.trim().toLowerCase(),
      passwordHash: data.passwordHash,
      name: data.name.trim(),
      profileImageUrl: null,
    });
    return this.usersRepository.save(user);
  }

  /** อัปเดตเฉพาะคอลัมน์ของรหัสยืนยัน — ไม่ใช้ save() ทั้ง entity ที่จะเขียน resetCodeAttempts ค่าเก่าทับ */
  async updateResetState(userId: string, patch: ResetStatePatch): Promise<void> {
    await this.usersRepository.update({ id: userId }, patch);
  }

  /**
   * จองสิทธิ์เดารหัสยืนยัน 1 ครั้งแบบ atomic (UPDATE ... WHERE attempts < max) — คืน false ถ้าครบโควตาแล้ว
   * ต้องจองก่อนเทียบรหัส ไม่งั้น request ที่ยิงพร้อมกันจะอ่านค่า attempts เดิมแล้วผ่านเช็คได้ทุกตัว
   */
  async consumeResetAttempt(userId: string, maxAttempts: number): Promise<boolean> {
    const result = await this.usersRepository
      .createQueryBuilder()
      .update(User)
      .set({ resetCodeAttempts: () => '"resetCodeAttempts" + 1' })
      .where('id = :id AND "resetCodeAttempts" < :max', { id: userId, max: maxAttempts })
      .execute();
    return result.affected === 1;
  }

  async save(user: User): Promise<User> {
    return this.usersRepository.save(user);
  }

  async remove(user: User): Promise<void> {
    await this.usersRepository.remove(user);
  }
}
