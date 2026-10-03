import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review, ReviewReply } from './review.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { CreateReplyDto } from './dto/create-reply.dto';
import { User } from '../users/user.entity';
import { Recipe } from '../recipes/recipe.entity';
import { RecipesService } from '../recipes/recipes.service';

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

  async create(recipeId: string, dto: CreateReviewDto, user: User): Promise<Review> {
    await this.recipesService.assertExists(recipeId);

    // Insert and recompute the recipe's rating together, so the stored average always matches the reviews.
    return this.reviewsRepository.manager.transaction(async (manager) => {
      const reviews = manager.getRepository(Review);
      const review = await reviews.save(
        reviews.create({
          recipeId,
          userId: user.id,
          userName: user.name,
          rating: dto.rating,
          content: dto.content,
          imageUrls: dto.imageUrls ?? [],
        }),
      );

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
