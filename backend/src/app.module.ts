import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { RecipesModule } from './recipes/recipes.module';
import { FavoritesModule } from './favorites/favorites.module';
import { ReviewsModule } from './reviews/reviews.module';
import { CommentsModule } from './comments/comments.module';
import { MealPlanModule } from './meal-plan/meal-plan.module';
import { SeedModule } from './seed/seed.module';
import { MetricsModule } from './metrics/metrics.module';
import { HealthModule } from './health/health.module';
import { validateEnv } from './config/env.validation';
import { DEFAULT_RATE_LIMIT } from './common/rate-limit';
import { databaseOptions } from './database/database.config';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    TypeOrmModule.forRoot(databaseOptions()),
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
