import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { CreateRecipeDto } from '../src/recipes/dto/create-recipe.dto';
import { Recipe } from '../src/recipes/recipe.entity';
import { RecipesService } from '../src/recipes/recipes.service';
import { User } from '../src/users/user.entity';

const owner = { id: 'owner-1', name: 'Owner' } as User;
const stranger = { id: 'stranger-1', name: 'Stranger' } as User;

const minimalDto: CreateRecipeDto = {
  name: 'Pad Krapao',
  emoji: '🌶️',
  category: 'อาหารจานเดียว',
  country: 'ไทย',
  cookTimeMinutes: 15,
  difficulty: 'ง่าย',
  ingredients: ['หมูสับ', 'ใบกะเพรา'],
  steps: ['ผัดหมู', 'ใส่กะเพรา'],
};

describe('RecipesService', () => {
  let service: RecipesService;
  let repo: {
    find: jest.Mock;
    findOne: jest.Mock;
    create: jest.Mock;
    save: jest.Mock;
    remove: jest.Mock;
  };

  beforeEach(async () => {
    repo = {
      find: jest.fn(),
      findOne: jest.fn(),
      create: jest.fn((data: Partial<Recipe>) => ({ ...data }) as Recipe),
      save: jest.fn(async (recipe: Recipe) => ({ ...recipe, id: recipe.id ?? 'recipe-1' })),
      remove: jest.fn(async () => undefined),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [RecipesService, { provide: getRepositoryToken(Recipe), useValue: repo }],
    }).compile();

    service = moduleRef.get(RecipesService);
  });

  describe('findOne', () => {
    it('throws NotFoundException when the recipe does not exist', async () => {
      repo.findOne.mockResolvedValue(null);
      await expect(service.findOne('missing')).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('create', () => {
    it('fills defaults for optional fields and records the uploader', async () => {
      const saved = await service.create(minimalDto, owner);

      expect(saved).toMatchObject({
        name: 'Pad Krapao',
        imageUrl: '',
        imageUrls: [],
        prepTimeMinutes: 10,
        servings: 2,
        ingredientItems: [],
        nutrition: null,
        dietTags: [],
        season: 'ตลอดปี',
        isRecommended: false,
        isOfficial: false,
        uploaderId: 'owner-1',
        uploaderName: 'Owner',
      });
    });

    it('keeps values the client did send', async () => {
      const saved = await service.create({ ...minimalDto, servings: 4, prepTimeMinutes: 5 }, owner);
      expect(saved.servings).toBe(4);
      expect(saved.prepTimeMinutes).toBe(5);
    });
  });

  describe('update', () => {
    beforeEach(() => {
      repo.findOne.mockResolvedValue({ id: 'recipe-1', name: 'Old', uploaderId: owner.id } as Recipe);
    });

    it('lets the uploader change their own recipe', async () => {
      const updated = await service.update('recipe-1', { name: 'New' }, owner);
      expect(updated.name).toBe('New');
      expect(repo.save).toHaveBeenCalled();
    });

    it('forbids anyone else from changing it', async () => {
      await expect(service.update('recipe-1', { name: 'Hacked' }, stranger)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(repo.save).not.toHaveBeenCalled();
    });
  });

  describe('remove', () => {
    beforeEach(() => {
      repo.findOne.mockResolvedValue({ id: 'recipe-1', uploaderId: owner.id } as Recipe);
    });

    it('lets the uploader delete their own recipe', async () => {
      await service.remove('recipe-1', owner);
      expect(repo.remove).toHaveBeenCalledTimes(1);
    });

    it('forbids anyone else from deleting it', async () => {
      await expect(service.remove('recipe-1', stranger)).rejects.toBeInstanceOf(ForbiddenException);
      expect(repo.remove).not.toHaveBeenCalled();
    });

    it('treats official seed recipes (no uploader) as not deletable', async () => {
      repo.findOne.mockResolvedValue({ id: 'seed-1', uploaderId: null } as Recipe);
      await expect(service.remove('seed-1', owner)).rejects.toBeInstanceOf(ForbiddenException);
    });
  });
});
