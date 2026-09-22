import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

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
