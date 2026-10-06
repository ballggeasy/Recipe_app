import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review, ReviewReply } from './review.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { CreateReplyDto } from './dto/create-reply.dto';
import { User } from '../users/user.entity';
import { Recipe } from '../recipes/recipe.entity';
import { RecipesService } from '../recipes/recipes.service';
import { LIMITS } from '../common/limits';
import { removeUploadedFile } from '../common/image-upload';

@Injectable()
export class ReviewsService {
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
   * One review per user per recipe: posting again updates that user's existing review instead of
   * adding another, so nobody can stuff a recipe's average. Likes, replies and photos stay; photos
   * are only replaced when the request sends `imageUrls`.
   *
   * The lookup and the write share one transaction, and every transaction starts with
   * BEGIN IMMEDIATE (database/immediate-transactions.ts), so two concurrent posts, even on
   * different replicas, can't both miss the existing row. There is no unique index because the
   * seeded reviews all share userId 'seed'.
   */
  async create(recipeId: string, dto: CreateReviewDto, user: User): Promise<Review> {
    await this.recipesService.assertExists(recipeId);

    // Save and recompute the recipe's rating together, so the stored average always matches the reviews.
    return this.reviewsRepository.manager.transaction(async (manager) => {
      const reviews = manager.getRepository(Review);
      const existing = await reviews.findOne({ where: { recipeId, userId: user.id } });
      const draft = existing ?? reviews.create({ recipeId, userId: user.id, imageUrls: [] });
      draft.userName = user.name;
      draft.rating = dto.rating;
      draft.content = dto.content;
      if (dto.imageUrls !== undefined) draft.imageUrls = dto.imageUrls;
      const review = await reviews.save(draft);

      // AVG/COUNT in SQL instead of loading every review of the recipe into memory.
      const aggregate = await reviews
        .createQueryBuilder('review')
        .select('AVG(review.rating)', 'average')
        .addSelect('COUNT(*)', 'count')
        .where('review.recipeId = :recipeId', { recipeId })
        .getRawOne<{ average: number | null; count: number }>();
      await manager.update(
        Recipe,
        { id: recipeId },
        { rating: Number(aggregate?.average ?? 0), reviewCount: Number(aggregate?.count ?? 0) },
      );

      return review;
    });
  }

  async toggleLike(id: string, userId: string): Promise<Review> {
    const review = await this.findOne(id);
    const liked = review.likedByUserIds.includes(userId);
    review.likedByUserIds = liked
      ? review.likedByUserIds.filter((u) => u !== userId)
      : [...review.likedByUserIds, userId];
    return this.reviewsRepository.save(review);
  }

  async remove(id: string, user: User): Promise<void> {
    const review = await this.findOne(id);
    if (review.userId !== user.id) {
      throw new ForbiddenException('ลบได้เฉพาะรีวิวของคุณเอง');
    }
    const recipeId = review.recipeId;

    await this.reviewsRepository.manager.transaction(async (manager) => {
      await manager.delete(ReviewReply, { reviewId: id });
      await manager.delete(Review, { id });

      const reviews = manager.getRepository(Review);
      const aggregate = await reviews
        .createQueryBuilder('review')
        .select('AVG(review.rating)', 'average')
        .addSelect('COUNT(*)', 'count')
        .where('review.recipeId = :recipeId', { recipeId })
        .getRawOne<{ average: number | null; count: number }>();
      await manager.update(
        Recipe,
        { id: recipeId },
        { rating: Number(aggregate?.average ?? 0), reviewCount: Number(aggregate?.count ?? 0) },
      );
    });
  }

  async addImage(id: string, imageUrl: string, user: User): Promise<Review> {
    const review = await this.findOne(id);
    if (review.userId !== user.id) {
      await removeUploadedFile(imageUrl);
      throw new ForbiddenException('แนบรูปได้เฉพาะรีวิวของคุณเอง');
    }
    const urls = review.imageUrls ?? [];
    if (urls.length >= LIMITS.imageUrls) {
      await removeUploadedFile(imageUrl);
      throw new BadRequestException('แนบรูปได้ไม่เกิน 10 รูป');
    }
    review.imageUrls = [...urls, imageUrl];
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
