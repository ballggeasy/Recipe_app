import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post, UseGuards } from '@nestjs/common';
import { MealPlanService } from './meal-plan.service';
import { CreateEntryDto } from './dto/create-entry.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { User } from '../users/user.entity';

@UseGuards(JwtAuthGuard)
@Controller('meal-plan')
export class MealPlanController {
  constructor(private readonly mealPlanService: MealPlanService) {}

  @Get()
  findAll(@CurrentUser() user: User) {
    return this.mealPlanService.findAllForUser(user.id);
  }

  @Post()
  create(@Body() dto: CreateEntryDto, @CurrentUser() user: User) {
    return this.mealPlanService.create(dto, user);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async remove(@Param('id') id: string, @CurrentUser() user: User) {
    await this.mealPlanService.remove(id, user);
    return { success: true };
  }
}
