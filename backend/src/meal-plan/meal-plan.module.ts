import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MealPlanEntry } from './meal-plan-entry.entity';
import { MealPlanService } from './meal-plan.service';
import { MealPlanController } from './meal-plan.controller';

@Module({
  imports: [TypeOrmModule.forFeature([MealPlanEntry])],
  controllers: [MealPlanController],
  providers: [MealPlanService],
})
export class MealPlanModule {}
