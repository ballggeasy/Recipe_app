import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Recipe } from './recipe.entity';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { User } from '../users/user.entity';
import { removeUploadedFile } from '../common/image-upload';

@Injectable()
export class RecipesService {
  constructor(
    @InjectRepository(Recipe)
    private readonly recipesRepository: Repository<Recipe>,
  ) {}

  findAll(): Promise<Recipe[]> {
    return this.recipesRepository.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: string): Promise<Recipe> {
    const recipe = await this.recipesRepository.findOne({ where: { id } });
    if (!recipe) {
      throw new NotFoundException('ไม่พบสูตรอาหารนี้');
    }
    return recipe;
  }

  create(dto: CreateRecipeDto, user: User): Promise<Recipe> {
    const recipe = this.recipesRepository.create({
      ...dto,
      imageUrl: dto.imageUrl ?? '',
      imageUrls: dto.imageUrls ?? [],
      prepTimeMinutes: dto.prepTimeMinutes ?? 10,
      servings: dto.servings ?? 2,
      ingredientItems: dto.ingredientItems ?? [],
      nutrition: dto.nutrition ?? null,
      dietTags: dto.dietTags ?? [],
      season: dto.season ?? 'ตลอดปี',
      tips: dto.tips ?? null,
      platingTips: dto.platingTips ?? null,
      videoUrl: dto.videoUrl ?? null,
      isRecommended: dto.isRecommended ?? false,
      isOfficial: false,
      uploaderId: user.id,
      uploaderName: user.name,
    });
    return this.recipesRepository.save(recipe);
  }

  async update(id: string, dto: UpdateRecipeDto, user: User): Promise<Recipe> {
    const recipe = await this.findOne(id);
    if (recipe.uploaderId !== user.id) {
      throw new ForbiddenException('แก้ไขได้เฉพาะสูตรที่คุณอัปโหลดเอง');
    }
    Object.assign(recipe, dto);
    return this.recipesRepository.save(recipe);
  }

  async remove(id: string, user: User): Promise<void> {
    const recipe = await this.findOne(id);
    if (recipe.uploaderId !== user.id) {
      throw new ForbiddenException('ลบได้เฉพาะสูตรที่คุณอัปโหลดเอง');
    }
    const uploadedImages = this.ownUploads(recipe.id, [recipe.imageUrl, ...(recipe.imageUrls ?? [])]);
    await this.recipesRepository.remove(recipe);
    uploadedImages.forEach((url) => void removeUploadedFile(url));
  }

  /**
   * Attaches an already-saved upload as the recipe's image (owner only) and deletes the
   * image previously uploaded for this recipe. If the caller may not edit the recipe, the
   * new file is deleted so rejected uploads don't pile up on disk.
   */
  async setImage(id: string, imageUrl: string, user: User): Promise<Recipe> {
    let recipe: Recipe;
    try {
      recipe = await this.findOne(id);
      if (recipe.uploaderId !== user.id) {
        throw new ForbiddenException('แก้ไขได้เฉพาะสูตรที่คุณอัปโหลดเอง');
      }
    } catch (error) {
      await removeUploadedFile(imageUrl);
      throw error;
    }

    const previous = this.ownUploads(recipe.id, [recipe.imageUrl, ...(recipe.imageUrls ?? [])]);
    recipe.imageUrl = imageUrl;
    recipe.imageUrls = [imageUrl];
    const saved = await this.recipesRepository.save(recipe);
    previous.filter((url) => url !== imageUrl).forEach((url) => void removeUploadedFile(url));
    return saved;
  }

  /**
   * Only files this API stored for this recipe (`/uploads/recipes/<id>-...`) are ever deleted,
   * so a client-supplied imageUrl can't make us remove someone else's file.
   */
  private ownUploads(recipeId: string, urls: string[]): string[] {
    const prefix = `/uploads/recipes/${recipeId}-`;
    return [...new Set(urls.filter((url) => url?.startsWith(prefix)))];
  }

  async applyRatingAggregate(recipeId: string, rating: number, reviewCount: number): Promise<void> {
    await this.recipesRepository.update({ id: recipeId }, { rating, reviewCount });
  }

  count(): Promise<number> {
    return this.recipesRepository.count();
  }

  saveMany(recipes: Partial<Recipe>[]): Promise<Recipe[]> {
    const entities = recipes.map((r) => this.recipesRepository.create(r));
    return this.recipesRepository.save(entities);
  }
}
