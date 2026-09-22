import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorite } from './favorite.entity';
import { FavoriteFolder } from './folder.entity';
import { CreateFolderDto } from './dto/create-folder.dto';

@Injectable()
export class FavoritesService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favoritesRepository: Repository<Favorite>,
    @InjectRepository(FavoriteFolder)
    private readonly foldersRepository: Repository<FavoriteFolder>,
  ) {}

  async listFavoriteIds(userId: string): Promise<string[]> {
    const favorites = await this.favoritesRepository.find({ where: { userId } });
    return favorites.map((f) => f.recipeId);
  }

  async addFavorite(userId: string, recipeId: string): Promise<void> {
    const existing = await this.favoritesRepository.findOne({ where: { userId, recipeId } });
    if (existing) return;
    await this.favoritesRepository.save(this.favoritesRepository.create({ userId, recipeId }));
  }

  async removeFavorite(userId: string, recipeId: string): Promise<void> {
    await this.favoritesRepository.delete({ userId, recipeId });
  }

  listFolders(userId: string): Promise<FavoriteFolder[]> {
    return this.foldersRepository.find({ where: { userId }, order: { createdAt: 'ASC' } });
  }

  createFolder(userId: string, dto: CreateFolderDto): Promise<FavoriteFolder> {
    const folder = this.foldersRepository.create({
      userId,
      name: dto.name,
      emoji: dto.emoji ?? '📁',
      recipeIds: [],
    });
    return this.foldersRepository.save(folder);
  }

  private async getOwnedFolder(userId: string, folderId: string): Promise<FavoriteFolder> {
    const folder = await this.foldersRepository.findOne({ where: { id: folderId, userId } });
    if (!folder) {
      throw new NotFoundException('ไม่พบโฟลเดอร์นี้');
    }
    return folder;
  }

  async deleteFolder(userId: string, folderId: string): Promise<void> {
    const folder = await this.getOwnedFolder(userId, folderId);
    await this.foldersRepository.remove(folder);
  }

  async addRecipeToFolder(userId: string, folderId: string, recipeId: string): Promise<FavoriteFolder> {
    const folder = await this.getOwnedFolder(userId, folderId);
    if (!folder.recipeIds.includes(recipeId)) {
      folder.recipeIds = [...folder.recipeIds, recipeId];
      await this.foldersRepository.save(folder);
    }
    return folder;
  }

  async removeRecipeFromFolder(userId: string, folderId: string, recipeId: string): Promise<FavoriteFolder> {
    const folder = await this.getOwnedFolder(userId, folderId);
    folder.recipeIds = folder.recipeIds.filter((id) => id !== recipeId);
    await this.foldersRepository.save(folder);
    return folder;
  }
}
