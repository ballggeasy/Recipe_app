import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MealPlanEntry } from './meal-plan-entry.entity';
import { MealPlanService } from './meal-plan.service';
import { MealPlanController } from './meal-plan.controller';
import { RecipesModule } from '../recipes/recipes.module';

@Module({
  imports: [TypeOrmModule.forFeature([MealPlanEntry]), RecipesModule],
  controllers: [MealPlanController],
  providers: [MealPlanService],
})
export class MealPlanModule {}
