import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MealPlanEntry } from './meal-plan-entry.entity';
import { CreateEntryDto } from './dto/create-entry.dto';
import { User } from '../users/user.entity';

@Injectable()
export class MealPlanService {
  constructor(
    @InjectRepository(MealPlanEntry)
    private readonly entriesRepository: Repository<MealPlanEntry>,
  ) {}

  findAllForUser(userId: string): Promise<MealPlanEntry[]> {
    return this.entriesRepository.find({ where: { userId }, order: { date: 'ASC' } });
  }

  create(dto: CreateEntryDto, user: User): Promise<MealPlanEntry> {
    const entry = this.entriesRepository.create({
      userId: user.id,
      recipeId: dto.recipeId,
      date: new Date(dto.date),
      mealType: dto.mealType,
      servings: dto.servings ?? 1,
    });
    return this.entriesRepository.save(entry);
  }

  async remove(id: string, user: User): Promise<void> {
    const entry = await this.entriesRepository.findOne({ where: { id } });
    if (!entry) {
      throw new NotFoundException('ไม่พบรายการนี้ในแผนมื้ออาหาร');
    }
    if (entry.userId !== user.id) {
      throw new ForbiddenException('ลบได้เฉพาะรายการของคุณเอง');
    }
    await this.entriesRepository.remove(entry);
  }
}
