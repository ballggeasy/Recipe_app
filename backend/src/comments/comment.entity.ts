import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('comments')
export class Comment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  recipeId: string;

  @Column()
  userId: string;

  @Column()
  userName: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'text', nullable: true })
  imageUrl: string | null;

  @Column({ type: 'simple-json', default: '[]' })
  mentions: string[];

  @Column({ type: 'text', nullable: true })
  parentId: string | null;

  @CreateDateColumn()
  createdAt: Date;
}
