import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post, UseGuards } from '@nestjs/common';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { User } from '../users/user.entity';

@Controller('recipes/:recipeId/comments')
export class RecipeCommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @Get()
  findForRecipe(@Param('recipeId') recipeId: string) {
    return this.commentsService.findForRecipe(recipeId);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(
    @Param('recipeId') recipeId: string,
    @Body() dto: CreateCommentDto,
    @CurrentUser() user: User,
  ) {
    return this.commentsService.create(recipeId, dto, user);
  }
}

@Controller('comments')
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async remove(@Param('id') id: string, @CurrentUser() user: User) {
    await this.commentsService.remove(id, user);
    return { success: true };
  }
}
