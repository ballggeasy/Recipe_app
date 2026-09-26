import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  passwordHash: string;

  @Column()
  name: string;

  @Column({ type: 'text', nullable: true })
  profileImageUrl: string | null;

  // รหัสยืนยันสำหรับตั้งรหัสผ่านใหม่ (เก็บเป็น hash) — null เมื่อไม่มีคำขอที่ค้างอยู่
  @Column({ type: 'text', nullable: true })
  resetCodeHash: string | null;

  @Column({ type: 'datetime', nullable: true })
  resetCodeExpiresAt: Date | null;

  @Column({ default: 0 })
  resetCodeAttempts: number;

  @CreateDateColumn()
  createdAt: Date;
}
