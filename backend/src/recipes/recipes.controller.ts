import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import { RecipesService } from './recipes.service';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { User } from '../users/user.entity';
import { imageUploadOptions, uploadedFileUrl } from '../common/image-upload';
import { AI_RATE_LIMIT } from '../common/rate-limit';

@Controller('recipes')
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Get()
  findAll() {
    return this.recipesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.recipesService.findOneAndCountView(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Body() dto: CreateRecipeDto, @CurrentUser() user: User) {
    return this.recipesService.create(dto, user);
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateRecipeDto, @CurrentUser() user: User) {
    return this.recipesService.update(id, dto, user);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/image')
  @UseInterceptors(
    FileInterceptor(
      'file',
      imageUploadOptions('recipes', (req) => req.params.id),
    ),
  )
  uploadImage(@Param('id') id: string, @UploadedFile() file: Express.Multer.File, @CurrentUser() user: User) {
    if (!file) {
      throw new BadRequestException('ไม่พบไฟล์รูปภาพ');
    }
    return this.recipesService.setImage(id, uploadedFileUrl('recipes', file.filename), user);
  }

  /** Re-runs the AI nutrition estimate now (owner only). Creating a recipe or changing its photo does this automatically. */
  @UseGuards(JwtAuthGuard)
  @Throttle(AI_RATE_LIMIT)
  @Post(':id/nutrition/estimate')
  estimateNutrition(@Param('id') id: string, @CurrentUser() user: User) {
    return this.recipesService.estimateNutrition(id, user);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Param('id') id: string, @CurrentUser() user: User) {
    return this.recipesService.remove(id, user);
  }
}
