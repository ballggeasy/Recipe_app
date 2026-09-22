import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post, UseGuards } from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { CreateFolderDto } from './dto/create-folder.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { User } from '../users/user.entity';

@UseGuards(JwtAuthGuard)
@Controller()
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get('favorites')
  listFavorites(@CurrentUser() user: User) {
    return this.favoritesService.listFavoriteIds(user.id);
  }

  @Post('favorites/:recipeId')
  @HttpCode(HttpStatus.OK)
  async addFavorite(@Param('recipeId') recipeId: string, @CurrentUser() user: User) {
    await this.favoritesService.addFavorite(user.id, recipeId);
    return { success: true };
  }

  @Delete('favorites/:recipeId')
  @HttpCode(HttpStatus.OK)
  async removeFavorite(@Param('recipeId') recipeId: string, @CurrentUser() user: User) {
    await this.favoritesService.removeFavorite(user.id, recipeId);
    return { success: true };
  }

  @Get('folders')
  listFolders(@CurrentUser() user: User) {
    return this.favoritesService.listFolders(user.id);
  }

  @Post('folders')
  createFolder(@Body() dto: CreateFolderDto, @CurrentUser() user: User) {
    return this.favoritesService.createFolder(user.id, dto);
  }

  @Delete('folders/:id')
  @HttpCode(HttpStatus.OK)
  async deleteFolder(@Param('id') id: string, @CurrentUser() user: User) {
    await this.favoritesService.deleteFolder(user.id, id);
    return { success: true };
  }

  @Post('folders/:id/recipes/:recipeId')
  addRecipeToFolder(
    @Param('id') id: string,
    @Param('recipeId') recipeId: string,
    @CurrentUser() user: User,
  ) {
    return this.favoritesService.addRecipeToFolder(user.id, id, recipeId);
  }

  @Delete('folders/:id/recipes/:recipeId')
  removeRecipeFromFolder(
    @Param('id') id: string,
    @Param('recipeId') recipeId: string,
    @CurrentUser() user: User,
  ) {
    return this.favoritesService.removeRecipeFromFolder(user.id, id, recipeId);
  }
}
