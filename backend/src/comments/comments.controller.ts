import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { User } from '../users/user.entity';
import { imageUploadOptions, uploadedFileUrl } from '../common/image-upload';

@Controller('recipes/:recipeId/comments')
export class RecipeCommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @Get()
  findForRecipe(@Param('recipeId') recipeId: string) {
    return this.commentsService.findForRecipe(recipeId);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Param('recipeId') recipeId: string, @Body() dto: CreateCommentDto, @CurrentUser() user: User) {
    return this.commentsService.create(recipeId, dto, user);
  }
}

@Controller('comments')
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @UseGuards(JwtAuthGuard)
  @Post(':id/image')
  @UseInterceptors(
    FileInterceptor(
      'file',
      imageUploadOptions('comments', (req) => req.params.id),
    ),
  )
  setImage(@Param('id') id: string, @UploadedFile() file: Express.Multer.File, @CurrentUser() user: User) {
    if (!file) {
      throw new BadRequestException('ไม่พบไฟล์รูปภาพ');
    }
    return this.commentsService.setImage(id, uploadedFileUrl('comments', file.filename), user);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async remove(@Param('id') id: string, @CurrentUser() user: User) {
    await this.commentsService.remove(id, user);
    return { success: true };
  }
}
