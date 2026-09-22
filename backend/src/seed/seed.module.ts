import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Recipe } from '../recipes/recipe.entity';
import { Review, ReviewReply } from '../reviews/review.entity';
import { Comment } from '../comments/comment.entity';
import { SeedService } from './seed.service';

@Module({
  imports: [TypeOrmModule.forFeature([Recipe, Review, ReviewReply, Comment])],
  providers: [SeedService],
})
export class SeedModule {}
