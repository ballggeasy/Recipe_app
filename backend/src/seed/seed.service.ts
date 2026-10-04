import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Recipe } from '../recipes/recipe.entity';
import { Review, ReviewReply } from '../reviews/review.entity';
import { Comment } from '../comments/comment.entity';
import { commentSeeds, recipeSeeds, reviewSeeds } from './seed-data';

@Injectable()
export class SeedService implements OnApplicationBootstrap {
  private readonly logger = new Logger(SeedService.name);

  constructor(
    @InjectRepository(Recipe) private readonly recipesRepository: Repository<Recipe>,
    @InjectRepository(Review) private readonly reviewsRepository: Repository<Review>,
    @InjectRepository(ReviewReply) private readonly repliesRepository: Repository<ReviewReply>,
    @InjectRepository(Comment) private readonly commentsRepository: Repository<Comment>,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    await this.recipesRepository
      .createQueryBuilder()
      .update(Recipe)
      .set({
        videoUrl:
          'https://www.youtube.com/results?search_query=%E0%B8%9C%E0%B8%B1%E0%B8%94%E0%B8%81%E0%B8%B0%E0%B9%80%E0%B8%9E%E0%B8%A3%E0%B8%B2%E0%B8%AB%E0%B8%A1%E0%B8%B9%E0%B8%AA%E0%B8%B1%E0%B8%9A',
      })
      .where('videoUrl LIKE :prefix', { prefix: 'placeholder:%' })
      .execute();

    const existingCount = await this.recipesRepository.count();
    if (existingCount > 0) {
      return;
    }

    this.logger.log('Seeding initial recipe catalog...');
    const legacyIdToNewId = new Map<string, string>();

    for (const seed of recipeSeeds) {
      const { legacyId, ...data } = seed;
      const recipe = await this.recipesRepository.save(this.recipesRepository.create(data));
      legacyIdToNewId.set(legacyId, recipe.id);
    }

    for (const seed of reviewSeeds) {
      const recipeId = legacyIdToNewId.get(seed.recipeLegacyId);
      if (!recipeId) continue;
      const review = await this.reviewsRepository.save(
        this.reviewsRepository.create({
          recipeId,
          userId: 'seed',
          userName: seed.userName,
          rating: seed.rating,
          content: seed.content,
          createdAt: seed.createdAt,
          likedByUserIds: Array.from({ length: seed.likeCount }, (_, i) => `seed-like-${i}`),
        }),
      );
      for (const reply of seed.replies) {
        await this.repliesRepository.save(
          this.repliesRepository.create({
            reviewId: review.id,
            userId: 'seed',
            userName: reply.userName,
            content: reply.content,
            createdAt: reply.createdAt,
          }),
        );
      }
    }

    for (const seed of commentSeeds) {
      const recipeId = legacyIdToNewId.get(seed.recipeLegacyId);
      if (!recipeId) continue;
      const comment = await this.commentsRepository.save(
        this.commentsRepository.create({
          recipeId,
          userId: 'seed',
          userName: seed.userName,
          content: seed.content,
          createdAt: seed.createdAt,
          mentions: seed.mentions,
          parentId: null,
        }),
      );
      for (const reply of seed.replies) {
        await this.commentsRepository.save(
          this.commentsRepository.create({
            recipeId,
            userId: 'seed',
            userName: reply.userName,
            content: reply.content,
            createdAt: reply.createdAt,
            mentions: reply.mentions,
            parentId: comment.id,
          }),
        );
      }
    }

    this.logger.log(
      `Seeded ${recipeSeeds.length} recipes, ${reviewSeeds.length} reviews, ${commentSeeds.length} comments.`,
    );
  }
}
