import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { User } from './users/user.entity';
import { RecipesModule } from './recipes/recipes.module';
import { Recipe } from './recipes/recipe.entity';
import { FavoritesModule } from './favorites/favorites.module';
import { Favorite } from './favorites/favorite.entity';
import { FavoriteFolder } from './favorites/folder.entity';
import { ReviewsModule } from './reviews/reviews.module';
import { Review, ReviewReply } from './reviews/review.entity';
import { CommentsModule } from './comments/comments.module';
import { Comment } from './comments/comment.entity';
import { MealPlanModule } from './meal-plan/meal-plan.module';
import { MealPlanEntry } from './meal-plan/meal-plan-entry.entity';
import { SeedModule } from './seed/seed.module';
import { MetricsModule } from './metrics/metrics.module';
import { HealthModule } from './health/health.module';
import { validateEnv } from './config/env.validation';
import { DEFAULT_RATE_LIMIT } from './common/rate-limit';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    TypeOrmModule.forRoot({
      type: 'sqlite',
      database: process.env.DB_PATH ?? './data/app.sqlite',
      entities: [User, Recipe, Favorite, FavoriteFolder, Review, ReviewReply, Comment, MealPlanEntry],
      synchronize: true,
    }),
    ThrottlerModule.forRoot({ throttlers: [{ name: 'default', ...DEFAULT_RATE_LIMIT }] }),
    UsersModule,
    AuthModule,
    RecipesModule,
    FavoritesModule,
    ReviewsModule,
    CommentsModule,
    MealPlanModule,
    SeedModule,
    MetricsModule,
    HealthModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
