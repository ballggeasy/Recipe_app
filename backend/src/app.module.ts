import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
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

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'sqlite',
      database: process.env.DB_PATH ?? './data/app.sqlite',
      entities: [User, Recipe, Favorite, FavoriteFolder, Review, ReviewReply, Comment, MealPlanEntry],
      synchronize: true,
    }),
    UsersModule,
    AuthModule,
    RecipesModule,
    FavoritesModule,
    ReviewsModule,
    CommentsModule,
    MealPlanModule,
    SeedModule,
  ],
})
export class AppModule {}
