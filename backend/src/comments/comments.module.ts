import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Comment } from './comment.entity';
import { CommentsService } from './comments.service';
import { RecipeCommentsController, CommentsController } from './comments.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Comment])],
  controllers: [RecipeCommentsController, CommentsController],
  providers: [CommentsService],
})
export class CommentsModule {}
