import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Review, ReviewReply } from './review.entity';
import { ReviewsService } from './reviews.service';
import { RecipeReviewsController, ReviewsController } from './reviews.controller';
import { RecipesModule } from '../recipes/recipes.module';

@Module({
  imports: [TypeOrmModule.forFeature([Review, ReviewReply]), RecipesModule],
  controllers: [RecipeReviewsController, ReviewsController],
  providers: [ReviewsService],
  exports: [ReviewsService],
})
export class ReviewsModule {}
