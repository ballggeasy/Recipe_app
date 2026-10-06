import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
@Index('IDX_users_google_id', ['googleId'], { unique: true })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  passwordHash: string;

  @Column()
  name: string;

  /** Google account (`sub`) linked to this user; null when the user only signs in with a password. */
  @Column({ type: 'text', nullable: true })
  googleId: string | null;

  @Column({ type: 'text', nullable: true })
  profileImageUrl: string | null;

  @CreateDateColumn()
  createdAt: Date;
}
