import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { CreateReplyDto } from './dto/create-reply.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { User } from '../users/user.entity';

@Controller('recipes/:recipeId/reviews')
export class RecipeReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Get()
  findForRecipe(@Param('recipeId') recipeId: string) {
    return this.reviewsService.findForRecipe(recipeId);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(
    @Param('recipeId') recipeId: string,
    @Body() dto: CreateReviewDto,
    @CurrentUser() user: User,
  ) {
    return this.reviewsService.create(recipeId, dto, user);
  }
}

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @UseGuards(JwtAuthGuard)
  @Post(':id/like')
  toggleLike(@Param('id') id: string, @CurrentUser() user: User) {
    return this.reviewsService.toggleLike(id, user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/report')
  report(@Param('id') id: string) {
    return this.reviewsService.report(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/replies')
  addReply(@Param('id') id: string, @Body() dto: CreateReplyDto, @CurrentUser() user: User) {
    return this.reviewsService.addReply(id, dto, user);
  }
}
