import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('reviews')
export class Review {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  recipeId: string;

  @Column()
  userId: string;

  @Column()
  userName: string;

  @Column({ type: 'float' })
  rating: number;

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'simple-json', default: '[]' })
  imageUrls: string[];

  @Column({ type: 'simple-json', default: '[]' })
  likedByUserIds: string[];

  @Column({ default: false })
  isReported: boolean;

  @OneToMany(() => ReviewReply, (reply) => reply.review, { cascade: true, eager: true })
  replies: ReviewReply[];

  @CreateDateColumn()
  createdAt: Date;
}

@Entity('review_replies')
export class ReviewReply {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Review, (review) => review.replies, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'reviewId' })
  review: Review;

  @Column()
  reviewId: string;

  @Column()
  userId: string;

  @Column()
  userName: string;

  @Column({ type: 'text' })
  content: string;

  @CreateDateColumn()
  createdAt: Date;
}
