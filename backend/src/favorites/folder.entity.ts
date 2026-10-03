import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

@Index('IDX_favorite_folders_user', ['userId'])
@Entity('favorite_folders')
export class FavoriteFolder {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  name: string;

  @Column({ default: '📁' })
  emoji: string;

  @Column({ type: 'simple-json', default: '[]' })
  recipeIds: string[];

  @CreateDateColumn()
  createdAt: Date;
}
