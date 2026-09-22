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
    const review = await this.reviewsRepository.save(
      this.reviewsRepository.create({
        recipeId,
        userId: user.id,
        userName: user.name,
        rating: dto.rating,
        content: dto.content,
        imageUrls: dto.imageUrls ?? [],
      }),
    );
    await this.refreshRecipeAggregate(recipeId);
    return review;
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
