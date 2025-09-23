import { Body, Controller, Get, Post, UseGuards, Param, Delete, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags, ApiOkResponse, ApiCreatedResponse, ApiParam } from '@nestjs/swagger';
import { MealsService } from './meals.service';
import { AddMealForDayDto } from './dto/add-meal-for-day.dto';
import { UpdateMealDto } from './dto/update-meal.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('meals')
@Controller('meals')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MealsController {
  constructor(private readonly mealsService: MealsService) {}


  @Post('day/my/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Add a meal for the current user on the given date' })
  @ApiParam({ name: 'date', example: '2025-01-10' })
  @ApiCreatedResponse({ description: 'Meal added for the day', schema: { example: { id: 'meal-uuid', name: 'Chicken Salad', calories: 350, type: 'LUNCH', date: '2025-01-10' } } })
  addMealForDay(@CurrentUser() user: any, @Param('date') date: string, @Body() dto: AddMealForDayDto) {
    return this.mealsService.addMealForDay(user.id, date, dto);
  }

  @Get('my/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'List meals for the current user and date' })
  @ApiParam({ name: 'date', example: '2025-01-10' })
  @ApiOkResponse({ description: 'List of meals for the day', schema: { example: [
    { mealId: 'id1', name: 'Chicken Salad', calories: 350, type: 'LUNCH' },
    { mealId: 'id2', name: 'Greek Yogurt', calories: 150, type: 'SNACK' }
  ] } })
  listMyMeals(@CurrentUser() user: any, @Param('date') date: string) {
    return this.mealsService.listMealsForDay(user.id, date);
  }

  @Delete('day/my/:date/:mealId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Delete a meal by its ID for the given date' })
  @ApiParam({ name: 'date', example: '2025-01-10' })
  @ApiParam({ name: 'mealId', example: 'meal-uuid' })
  @ApiOkResponse({ description: 'Deletion result', schema: { example: { ok: true } } })
  deleteMeal(@CurrentUser() user: any, @Param('date') date: string, @Param('mealId') mealId: string) {
    return this.mealsService.deleteMeal(user.id, date, mealId);
  }

  @Patch('day/my/:date/:mealId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Update a meal by its ID for the given date' })
  @ApiParam({ name: 'date', example: '2025-01-10' })
  @ApiParam({ name: 'mealId', example: 'meal-uuid' })
  @ApiOkResponse({ description: 'Updated meal', schema: { example: { id: 'meal-uuid', name: 'Grilled Fish', calories: 420, type: 'DINNER', date: '2025-01-10' } } })
  updateMeal(
    @CurrentUser() user: any,
    @Param('date') date: string,
    @Param('mealId') mealId: string,
    @Body() dto: UpdateMealDto,
  ) {
    return this.mealsService.updateMeal(user.id, date, mealId, dto);
  }

  @Get('daily-intake/my/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get total daily calorie intake for current user' })
  @ApiParam({ name: 'date', example: '2025-01-10' })
  @ApiOkResponse({ description: 'Total daily calorie intake for the date', schema: { example: { date: '2025-01-10', totalCaloriesIntake: 1220 } } })
  getMyDailyIntake(@CurrentUser() user: any, @Param('date') date: string) {
    return this.mealsService.getDailyIntake(user.id, date);
  }

  @Get('my/:date/meal-type/:type/summary')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get number of meals and total calories by MealType for the date' })
  @ApiParam({ name: 'date', example: '2025-01-10' })
  @ApiParam({ name: 'type', example: 'LUNCH' })
  @ApiOkResponse({ schema: { example: { date: '2025-01-10', type: 'LUNCH', count: 2, totalCalories: 750 } } })
  mealTypeSummary(
    @CurrentUser() user: any,
    @Param('date') date: string,
    @Param('type') type: string,
  ) {
    return this.mealsService.getMealTypeSummary(user.id, date, type);
  }

  @Get('my/:date/summary')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get per-meal-type counts and total calories for the date' })
  @ApiParam({ name: 'date', example: '2025-01-10' })
  @ApiOkResponse({ schema: { example: { date: '2025-01-10', totalCaloriesIntake: 1770, breakdown: [
    { type: 'BREAKFAST', count: 1, totalCalories: 320 },
    { type: 'LUNCH', count: 2, totalCalories: 850 },
    { type: 'DINNER', count: 1, totalCalories: 600 },
    { type: 'SNACK', count: 0, totalCalories: 0 }
  ] } } })
  allTypesSummary(@CurrentUser() user: any, @Param('date') date: string) {
    return this.mealsService.getAllMealTypesSummary(user.id, date);
  }
}

