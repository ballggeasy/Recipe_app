import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review, ReviewReply } from './review.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { CreateReplyDto } from './dto/create-reply.dto';
import { User } from '../users/user.entity';
import { RecipesService } from '../recipes/recipes.service';

@Injectable()
export class ReviewsService {
  // คิวของ create ที่ค้างอยู่ต่อ key (สูตร:ผู้ใช้) — ดู runExclusive
  private readonly pendingByKey = new Map<string, Promise<unknown>>();

  constructor(
    @InjectRepository(Review)
    private readonly reviewsRepository: Repository<Review>,
    @InjectRepository(ReviewReply)
    private readonly repliesRepository: Repository<ReviewReply>,
    private readonly recipesService: RecipesService,
  ) {}

  findForRecipe(recipeId: string): Promise<Review[]> {
    return this.reviewsRepository.find({
      where: { recipeId },
      order: { createdAt: 'DESC' },
    });
  }

  private async findOne(id: string): Promise<Review> {
    const review = await this.reviewsRepository.findOne({ where: { id } });
    if (!review) {
      throw new NotFoundException('ไม่พบรีวิวนี้');
    }
    return review;
  }

  /**
   * ผู้ใช้หนึ่งคนมีรีวิวได้หนึ่งรีวิวต่อสูตร — รีวิวซ้ำจะแก้รีวิวเดิมแทน เพื่อไม่ให้ปั่นคะแนนเฉลี่ยได้
   * รันทีละ request ต่อ (สูตร, ผู้ใช้) เพราะ find-แล้ว-insert ที่ยิงพร้อมกันจะไม่เจอกันแล้วสร้างซ้ำ
   * (ใส่ unique index ไม่ได้ เพราะรีวิวจาก seed ใช้ userId 'seed' ซ้ำกันหลายรีวิว)
   */
  create(recipeId: string, dto: CreateReviewDto, user: User): Promise<Review> {
    return this.runExclusive(`${recipeId}:${user.id}`, () => this.upsertReview(recipeId, dto, user));
  }

  private async upsertReview(recipeId: string, dto: CreateReviewDto, user: User): Promise<Review> {
    await this.recipesService.findOne(recipeId);

    const existing = await this.reviewsRepository.findOne({ where: { recipeId, userId: user.id } });
    const review = existing ?? this.reviewsRepository.create({ recipeId, userId: user.id });
    review.userName = user.name;
    review.rating = dto.rating;
    review.content = dto.content;
    review.imageUrls = dto.imageUrls ?? [];

    const saved = await this.reviewsRepository.save(review);
    await this.refreshRecipeAggregate(recipeId);
    return saved;
  }

  /** ต่อคิว task ที่ key เดียวกันให้รันทีละตัว (backend เป็น process เดียวบน sqlite จึงล็อกในหน่วยความจำได้) */
  private async runExclusive<T>(key: string, task: () => Promise<T>): Promise<T> {
    const previous = this.pendingByKey.get(key) ?? Promise.resolve();
    const current = previous.catch(() => undefined).then(task);
    this.pendingByKey.set(key, current);
    try {
      return await current;
    } finally {
      if (this.pendingByKey.get(key) === current) this.pendingByKey.delete(key);
    }
  }

  private async refreshRecipeAggregate(recipeId: string): Promise<void> {
    const reviews = await this.findForRecipe(recipeId);
    const reviewCount = reviews.length;
    const rating = reviewCount === 0 ? 0 : reviews.reduce((sum, r) => sum + r.rating, 0) / reviewCount;
    await this.recipesService.applyRatingAggregate(recipeId, rating, reviewCount);
  }

  async toggleLike(id: string, userId: string): Promise<Review> {
    const review = await this.findOne(id);
    const liked = review.likedByUserIds.includes(userId);
    review.likedByUserIds = liked
      ? review.likedByUserIds.filter((u) => u !== userId)
      : [...review.likedByUserIds, userId];
    return this.reviewsRepository.save(review);
  }

  async report(id: string): Promise<Review> {
    const review = await this.findOne(id);
    review.isReported = true;
    return this.reviewsRepository.save(review);
  }

  async addReply(id: string, dto: CreateReplyDto, user: User): Promise<Review> {
    const review = await this.findOne(id);
    await this.repliesRepository.save(
      this.repliesRepository.create({
        reviewId: review.id,
        userId: user.id,
        userName: user.name,
        content: dto.content,
      }),
    );
    return this.findOne(id);
  }
}
