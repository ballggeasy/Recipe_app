import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { CreateReplyDto } from './dto/create-reply.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { User } from '../users/user.entity';
import { imageUploadOptions, uploadedFileUrl } from '../common/image-upload';

@Controller('recipes/:recipeId/reviews')
export class RecipeReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Get()
  findForRecipe(@Param('recipeId') recipeId: string) {
    return this.reviewsService.findForRecipe(recipeId);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Param('recipeId') recipeId: string, @Body() dto: CreateReviewDto, @CurrentUser() user: User) {
    return this.reviewsService.create(recipeId, dto, user);
  }
}

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Param('id') id: string, @CurrentUser() user: User) {
    return this.reviewsService.remove(id, user);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/image')
  @UseInterceptors(
    FileInterceptor(
      'file',
      imageUploadOptions('reviews', (req) => req.params.id),
    ),
  )
  addImage(@Param('id') id: string, @UploadedFile() file: Express.Multer.File, @CurrentUser() user: User) {
    if (!file) {
      throw new BadRequestException('ไม่พบไฟล์รูปภาพ');
    }
    return this.reviewsService.addImage(id, uploadedFileUrl('reviews', file.filename), user);
  }

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
