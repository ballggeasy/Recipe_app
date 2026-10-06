import { BeforeApplicationShutdown, ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { readFile } from 'fs/promises';
import { IsNull, Repository } from 'typeorm';
import { Recipe } from './recipe.entity';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { User } from '../users/user.entity';
import { MAX_IMAGE_BYTES, removeUploadedFile, uploadedFilePath } from '../common/image-upload';
import { NutritionEstimator } from '../nutrition/nutrition-estimator';

/** What an AI nutrition estimate is based on; when one of these changes, the estimate is redone. */
function estimateInputs(recipe: Recipe): string {
  return JSON.stringify([recipe.name, recipe.servings, recipe.ingredients, recipe.imageUrl]);
}

@Injectable()
export class RecipesService implements BeforeApplicationShutdown {
  private readonly logger = new Logger(RecipesService.name);
  /** Background estimates still running, awaited on shutdown so none writes to a closed database. */
  private readonly pendingEstimates = new Set<Promise<void>>();

  constructor(
    @InjectRepository(Recipe)
    private readonly recipesRepository: Repository<Recipe>,
    private readonly nutritionEstimator: NutritionEstimator,
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

  /** Public detail view: counts the view (atomic increment, so concurrent readers don't lose counts). */
  async findOneAndCountView(id: string): Promise<Recipe> {
    const recipe = await this.findOne(id);
    await this.recipesRepository.increment({ id }, 'viewCount', 1);
    recipe.viewCount += 1;
    return recipe;
  }

  async create(dto: CreateRecipeDto, user: User): Promise<Recipe> {
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
      // Editorial flags are not user-settable: user recipes are never official or recommended.
      isRecommended: false,
      isOfficial: false,
      uploaderId: user.id,
      uploaderName: user.name,
    });
    const saved = await this.recipesRepository.save(recipe);
    this.estimateInBackground(saved);
    return saved;
  }

  async update(id: string, dto: UpdateRecipeDto, user: User): Promise<Recipe> {
    const recipe = await this.findOne(id);
    if (recipe.uploaderId !== user.id) {
      throw new ForbiddenException('แก้ไขได้เฉพาะสูตรที่คุณอัปโหลดเอง');
    }
    const inputsBefore = estimateInputs(recipe);
    Object.assign(recipe, dto);
    const saved = await this.recipesRepository.save(recipe);
    if (estimateInputs(saved) !== inputsBefore) this.estimateInBackground(saved);
    return saved;
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
    this.estimateInBackground(saved);
    return saved;
  }

  /** Owner asks for a fresh AI estimate now (e.g. the automatic one failed); replaces hand-entered values too. */
  async estimateNutrition(id: string, user: User): Promise<Recipe> {
    const recipe = await this.findOne(id);
    if (recipe.uploaderId !== user.id) {
      throw new ForbiddenException('ประเมินได้เฉพาะสูตรที่คุณอัปโหลดเอง');
    }
    return this.saveNutritionEstimate(recipe);
  }

  /**
   * Estimates nutrition from the recipe's photo (when there is one) and ingredients and stores it.
   * [image] overrides the stored photo, for recipes whose image only exists in the app.
   * If the recipe's name, servings, ingredients or photo change while the model is answering, the
   * estimate is dropped, since it no longer describes the recipe (the change starts its own estimate).
   */
  async saveNutritionEstimate(recipe: Recipe, image?: Buffer): Promise<Recipe> {
    const inputs = estimateInputs(recipe);
    const nutrition = await this.nutritionEstimator.estimate({
      name: recipe.name,
      servings: recipe.servings,
      ingredients: recipe.ingredients,
      image: image ?? (await this.loadImage(recipe.imageUrl)),
    });
    const current = await this.findOne(recipe.id);
    if (estimateInputs(current) !== inputs) return current;
    current.nutrition = nutrition;
    return this.recipesRepository.save(current);
  }

  /** Recipes the backfill job should estimate: those without nutrition, or every recipe with [all]. */
  findForNutritionBackfill(all: boolean): Promise<Recipe[]> {
    return this.recipesRepository.find({ where: all ? {} : { nutrition: IsNull() }, order: { createdAt: 'ASC' } });
  }

  /** Resolves once the background estimates started so far have finished (or failed). */
  async settleEstimates(): Promise<void> {
    await Promise.allSettled([...this.pendingEstimates]);
  }

  /** Nest calls this before closing the database connection, so no estimate writes to a closed one. */
  beforeApplicationShutdown(): Promise<void> {
    return this.settleEstimates();
  }

  /**
   * Fire-and-forget estimate after a recipe is created or its photo/ingredients change, so the meal
   * planner has numbers without anyone asking. Hand-entered nutrition is never overwritten here.
   */
  private estimateInBackground(recipe: Recipe): void {
    if (!this.nutritionEstimator.isEnabled) return;
    if (recipe.nutrition && recipe.nutrition.source !== 'ai') return;
    const task = this.saveNutritionEstimate(recipe)
      .then(() => undefined)
      .catch((error) => {
        this.logger.warn(
          `Nutrition estimate for ${recipe.id} failed: ${error instanceof Error ? error.message : error}`,
        );
      })
      .finally(() => this.pendingEstimates.delete(task));
    this.pendingEstimates.add(task);
  }

  /** The recipe photo: an upload is read from disk, a remote URL fetched; null when unavailable. */
  private async loadImage(imageUrl: string): Promise<Buffer | undefined> {
    if (!imageUrl) return undefined;
    try {
      const path = uploadedFilePath(imageUrl);
      if (path) return await readFile(path);
      if (!/^https?:\/\//.test(imageUrl)) return undefined;
      const response = await fetch(imageUrl, {
        headers: { 'User-Agent': 'RecipeApp/1.0 (nutrition estimate)' },
        signal: AbortSignal.timeout(15_000),
      });
      if (!response.ok) return undefined;
      const bytes = Buffer.from(await response.arrayBuffer());
      return bytes.length <= MAX_IMAGE_BYTES ? bytes : undefined;
    } catch {
      return undefined; // estimate from the ingredients alone
    }
  }

  /**
   * Only files this API stored for this recipe (`/uploads/recipes/<id>-...`) are ever deleted,
   * so a client-supplied imageUrl can't make us remove someone else's file.
   */
  private ownUploads(recipeId: string, urls: string[]): string[] {
    const prefix = `/uploads/recipes/${recipeId}-`;
    return [...new Set(urls.filter((url) => url?.startsWith(prefix)))];
  }

  /** Throws 404 unless the recipe exists. Used by modules that attach data (reviews, comments, favorites, ...) to a recipe. */
  async assertExists(id: string): Promise<void> {
    if (!(await this.recipesRepository.exist({ where: { id } }))) {
      throw new NotFoundException('ไม่พบสูตรอาหารนี้');
    }
  }

  count(): Promise<number> {
    return this.recipesRepository.count();
  }

  saveMany(recipes: Partial<Recipe>[]): Promise<Recipe[]> {
    const entities = recipes.map((r) => this.recipesRepository.create(r));
    return this.recipesRepository.save(entities);
  }
}
