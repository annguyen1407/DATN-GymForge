import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  ParseUUIDPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery, ApiParam, ApiBody, ApiOkResponse } from '@nestjs/swagger';
import { WorkoutPlansService } from './workout-plans.service';
import { DayStatsResponseDto } from './dto/day-stats.dto';
import { CreateWorkoutPlanDto } from './dto/create-workout-plan.dto';
import { UpdateWorkoutPlanDto } from './dto/update-workout-plan.dto';
import { CreateWorkoutExerciseDto } from './dto/create-workout-exercise.dto';
import { CreateFromTemplateDto } from './dto/create-from-template.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';
import { CreateWorkoutDayDto } from './dto/create-workout-day.dto';
import { UpdateWorkoutDayDto } from './dto/update-workout-day.dto';

@ApiTags('workout-plans')
@Controller('workout-plans')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class WorkoutPlansController {
  constructor(private readonly workoutPlansService: WorkoutPlansService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Create a new workout plan' })
  @ApiResponse({ status: 201, description: 'Workout plan created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  create(@Body() createWorkoutPlanDto: CreateWorkoutPlanDto, @CurrentUser() user: any) {
    return this.workoutPlansService.create(createWorkoutPlanDto, user.id);
  }

  @Get()
  @ApiOperation({ summary: 'Get all workout plans' })
  @ApiResponse({ status: 200, description: 'List of all workout plans' })
  @ApiQuery({ name: 'userId', required: false, description: 'Filter by user ID' })
  findAll(@Query('userId') userId: string | undefined, @CurrentUser() user: any) {
    return this.workoutPlansService.findAll(userId, user?.id);
  }

  @Get('templates')
  @ApiOperation({ summary: 'Get all workout plan templates' })
  @ApiResponse({ status: 200, description: 'List of all workout plan templates' })
  @ApiQuery({ name: 'planType', required: false, description: 'Filter templates by plan type' })
  @ApiQuery({ name: 'premiumOnly', required: false, description: 'Filter by premium-only flag (true/false)' })
  findTemplates(
    @Query('planType') planType?: string,
    @Query('premiumOnly') premiumOnly?: string,
    @CurrentUser() user?: any,
  ) {
    return this.workoutPlansService.findTemplates(planType, premiumOnly, user?.id);
  }

  @Get('templates/my')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Get templates created by current user' })
  @ApiResponse({ status: 200, description: 'List of templates created by current user' })
  findMyTemplates(@CurrentUser() user: any) {
    return this.workoutPlansService.findTemplatesByCreator(user.id);
  }

  @Patch(':id/template-status')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Toggle template status of a workout plan' })
  @ApiResponse({ status: 200, description: 'Template status updated successfully' })
  @ApiResponse({ status: 404, description: 'Workout plan not found' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient permissions' })
  toggleTemplateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { isTemplate: boolean },
    @CurrentUser() user: any,
  ) {
    return this.workoutPlansService.toggleTemplateStatus(id, body.isTemplate, user.id);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get workout plans by user ID' })
  @ApiResponse({ status: 200, description: 'User workout plans' })
  findByUserId(@Param('userId', ParseUUIDPipe) userId: string, @CurrentUser() user: any) {
    return this.workoutPlansService.findByUserId(userId, user?.id);
  }

  @Post('clone-template/:templateId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Create a workout plan from a template' })
  @ApiResponse({ status: 201, description: 'Workout plan created from template successfully' })
  @ApiResponse({ status: 404, description: 'Template not found' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  createFromTemplate(
    @Param('templateId', ParseUUIDPipe) templateId: string,
    @Body() createFromTemplateDto: CreateFromTemplateDto,
    @CurrentUser() user: any,
  ) {
    return this.workoutPlansService.createFromTemplate(templateId, createFromTemplateDto, user.id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Update a workout plan' })
  @ApiResponse({ status: 200, description: 'Workout plan updated successfully' })
  @ApiResponse({ status: 404, description: 'Workout plan not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateWorkoutPlanDto: UpdateWorkoutPlanDto,
    @CurrentUser() user: any,
  ) {
    return this.workoutPlansService.update(id, updateWorkoutPlanDto, user.id);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Delete a workout plan' })
  @ApiResponse({ status: 200, description: 'Workout plan deleted successfully' })
  @ApiResponse({ status: 404, description: 'Workout plan not found' })
  remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: any) {
    return this.workoutPlansService.remove(id, user.id);
  }

  // Workout Day endpoints
  @Post(':planId/days')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Create a day for a workout plan' })
  @ApiResponse({ status: 201, description: 'Day created successfully' })
  @ApiParam({ name: 'planId', required: true, description: 'Workout plan ID (UUID)' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        dayNumber: { type: 'number', example: 1, description: 'Day number in the workout plan' },
        date: { type: 'string', format: 'date', example: '2025-01-20', description: 'Scheduled calendar date (optional)' },
      },
      required: [],
    },
  })
  createDay(@Param('planId', ParseUUIDPipe) planId: string, @Body() dto: Omit<CreateWorkoutDayDto, 'workoutPlanId'>) {
    return this.workoutPlansService.createDay({ ...dto, workoutPlanId: planId });
  }

  @Get(':planId/days')
  @ApiOperation({ summary: 'List days of a workout plan' })
  listDays(@Param('planId', ParseUUIDPipe) planId: string, @CurrentUser() user: any) {
    return this.workoutPlansService.listDays(planId, user?.id);
  }

  @Patch('days/:dayId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Update a workout day' })
  @ApiBody({ type: UpdateWorkoutDayDto })
  updateDay(@Param('dayId', ParseUUIDPipe) dayId: string, @Body() dto: UpdateWorkoutDayDto) {
    return this.workoutPlansService.updateDay(dayId, dto);
  }

  @Delete('days/:dayId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Delete a workout day' })
  removeDay(@Param('dayId', ParseUUIDPipe) dayId: string) {
    return this.workoutPlansService.removeDay(dayId);
  }

  @Get('days/:dayId/stats')
  @ApiOperation({ summary: 'Get statistics for a workout day including its parent plan' })
  @ApiOkResponse({ description: 'Parent plan + day meta + aggregated stats by workout exercise', type: DayStatsResponseDto })
  getDayStats(@Param('dayId', ParseUUIDPipe) dayId: string, @CurrentUser() user: any) {
    return this.workoutPlansService.getDayStats(dayId, user?.id);
  }

  // Workout Exercise endpoints
  @Post('exercises')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Add exercise to workout plan/day' })
  @ApiResponse({ status: 201, description: 'Exercise added successfully' })
  @ApiBody({ type: CreateWorkoutExerciseDto })
  addExercise(@Body() createWorkoutExerciseDto: CreateWorkoutExerciseDto) {
    return this.workoutPlansService.addExercise(createWorkoutExerciseDto);
  }

  @Delete('exercises/:exerciseId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Remove exercise from workout plan/day' })
  @ApiResponse({ status: 200, description: 'Exercise removed successfully' })
  removeExercise(@Param('exerciseId', ParseUUIDPipe) exerciseId: string) {
    return this.workoutPlansService.removeExercise(exerciseId);
  }

  @Patch('exercises/:exerciseId')



  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Update exercise in workout plan/day' })
  @ApiResponse({ status: 200, description: 'Exercise updated successfully' })
  @ApiBody({ type: CreateWorkoutExerciseDto, description: 'Provide any subset of fields to update' })
  updateExercise(
    @Param('exerciseId', ParseUUIDPipe) exerciseId: string,
    @Body() updateData: Partial<CreateWorkoutExerciseDto>,
  ) {
    return this.workoutPlansService.updateExercise(exerciseId, updateData);
  }

  @Get('exercises/:workoutExerciseId/logs')
  @ApiOperation({ summary: 'List logs for a workout exercise' })
  @ApiResponse({ status: 200, description: 'List of logs for the workout exercise' })
  listExerciseLogs(@Param('workoutExerciseId', ParseUUIDPipe) workoutExerciseId: string, @CurrentUser() user: any) {
    return this.workoutPlansService.listExerciseLogs(workoutExerciseId, user?.id);
  }

  @Get('exercises')
  @ApiOperation({ summary: 'Get workout exercises with optional filtering' })
  @ApiResponse({ status: 200, description: 'List of workout exercises' })
  @ApiQuery({ name: 'workoutPlanId', required: false, description: 'Filter by workout plan ID' })
  @ApiQuery({ name: 'workoutDayId', required: false, description: 'Filter by workout day ID' })
  @ApiQuery({ name: 'dayNumber', required: false, description: 'Filter by day number (legacy)' })
  @ApiQuery({ name: 'exerciseId', required: false, description: 'Filter by exercise ID' })
  getWorkoutExercises(
    @Query('workoutPlanId') workoutPlanId?: string,
    @Query('workoutDayId') workoutDayId?: string,
    @Query('dayNumber') dayNumber?: string,
    @Query('exerciseId') exerciseId?: string,
    @CurrentUser() user?: any,
  ) {
    return this.workoutPlansService.getWorkoutExercises(
      {
        workoutPlanId,
        workoutDayId,
        dayNumber: dayNumber ? parseInt(dayNumber) : undefined,
        exerciseId,
      },
      user?.id,
    );
  }

  // Place generic param route last to avoid conflicts with static paths like 'exercises'
  @Get(':id')
  @ApiOperation({ summary: 'Get a workout plan by ID' })
  @ApiResponse({ status: 200, description: 'Workout plan details' })
  @ApiResponse({ status: 404, description: 'Workout plan not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: any) {
    return this.workoutPlansService.findOne(id, user?.id);
  }
}
