import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Comment } from './comment.entity';
import { CommentsService } from './comments.service';
import { RecipeCommentsController, CommentsController } from './comments.controller';
import { RecipesModule } from '../recipes/recipes.module';

@Module({
  imports: [TypeOrmModule.forFeature([Comment]), RecipesModule],
  controllers: [RecipeCommentsController, CommentsController],
  providers: [CommentsService],
})
export class CommentsModule {}
