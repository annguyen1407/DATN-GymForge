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
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ExerciseLogsService } from './exercise-logs.service';
import { CreateExerciseLogDto } from './dto/create-exercise-log.dto';
import { QuickLogExerciseDto } from './dto/quick-log-exercise.dto';
import { UpdateExerciseLogDto } from './dto/update-exercise-log.dto';

import {
  DailyExerciseStatsDto,
  WeeklyExerciseStatsDto,
  MonthlyExerciseStatsDto,
  WorkoutPlanProgressDto,
  ExercisePerformanceDto,
} from './dto/exercise-statistics.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';
import { UpdateDailyLogDto } from './dto/update-daily-log.dto';

@ApiTags('exercise-logs')
@Controller('exercise-logs')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ExerciseLogsController {
  constructor(private readonly exerciseLogsService: ExerciseLogsService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Log a new exercise session' })
  @ApiResponse({ status: 201, description: 'Exercise logged successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 404, description: 'User, workout exercise, or workout plan not found' })
  create(@Body() createExerciseLogDto: CreateExerciseLogDto) {
    return this.exerciseLogsService.createExerciseLog(createExerciseLogDto);
  }

  @Post('quick-log')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Quick log an exercise with sets for current user' })
  @ApiResponse({ status: 201, description: 'Exercise logged successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 404, description: 'Workout exercise or exercise not found' })
  quickLog(@Body() quickLogDto: QuickLogExerciseDto, @CurrentUser() user: any) {
    return this.exerciseLogsService.quickLogExercise(user.id, quickLogDto);
  }

  @Get('user/:userId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get exercise logs for a user' })
  @ApiResponse({ status: 200, description: 'User exercise logs' })
  @ApiQuery({ name: 'startDate', required: false, description: 'Start date filter (YYYY-MM-DD)' })
  @ApiQuery({ name: 'endDate', required: false, description: 'End date filter (YYYY-MM-DD)' })
  findUserLogs(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.exerciseLogsService.findUserExerciseLogs(userId, startDate, endDate);
  }

  @Get('my-logs')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get current user exercise logs' })
  @ApiResponse({ status: 200, description: 'Current user exercise logs' })
  @ApiQuery({ name: 'startDate', required: false, description: 'Start date filter (YYYY-MM-DD)' })
  @ApiQuery({ name: 'endDate', required: false, description: 'End date filter (YYYY-MM-DD)' })
  findMyLogs(
    @CurrentUser() user: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.exerciseLogsService.findUserExerciseLogs(user.id, startDate, endDate);
  }

  @Get('stats/daily/my/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get daily exercise statistics for current user' })
  @ApiResponse({ status: 200, description: 'Daily exercise statistics', type: DailyExerciseStatsDto })
  getMyDailyStats(
    @CurrentUser() user: any,
    @Param('date') date: string,
  ): Promise<DailyExerciseStatsDto> {
    return this.exerciseLogsService.getDailyStats(user.id, date);
  }

  @Get('stats/daily/:userId/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get daily exercise statistics for a user' })
  @ApiResponse({ status: 200, description: 'Daily exercise statistics', type: DailyExerciseStatsDto })
  getDailyStats(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('date') date: string,
  ): Promise<DailyExerciseStatsDto> {
    return this.exerciseLogsService.getDailyStats(userId, date);
  }

  @Get('stats/weekly/my/:weekStart')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get weekly exercise statistics for current user' })
  @ApiResponse({ status: 200, description: 'Weekly exercise statistics', type: WeeklyExerciseStatsDto })
  getMyWeeklyStats(
    @CurrentUser() user: any,
    @Param('weekStart') weekStart: string,
  ): Promise<WeeklyExerciseStatsDto> {
    return this.exerciseLogsService.getWeeklyStats(user.id, weekStart);
  }

  @Get('stats/weekly/:userId/:weekStart')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get weekly exercise statistics for a user' })
  @ApiResponse({ status: 200, description: 'Weekly exercise statistics', type: WeeklyExerciseStatsDto })
  getWeeklyStats(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('weekStart') weekStart: string,
  ): Promise<WeeklyExerciseStatsDto> {
    return this.exerciseLogsService.getWeeklyStats(userId, weekStart);
  }

  @Get('stats/monthly/my/:month')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get monthly exercise statistics for current user' })
  @ApiResponse({ status: 200, description: 'Monthly exercise statistics', type: MonthlyExerciseStatsDto })
  getMyMonthlyStats(
    @CurrentUser() user: any,
    @Param('month') month: string,
  ): Promise<MonthlyExerciseStatsDto> {
    return this.exerciseLogsService.getMonthlyStats(user.id, month);
  }

  @Get('stats/monthly/:userId/:month')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get monthly exercise statistics for a user' })
  @ApiResponse({ status: 200, description: 'Monthly exercise statistics', type: MonthlyExerciseStatsDto })
  getMonthlyStats(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('month') month: string,
  ): Promise<MonthlyExerciseStatsDto> {
    return this.exerciseLogsService.getMonthlyStats(userId, month);
  }

  @Get('workout-plan-progress/my/:workoutPlanId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get workout plan progress for current user' })
  @ApiResponse({ status: 200, description: 'Workout plan progress', type: WorkoutPlanProgressDto })
  getMyWorkoutPlanProgress(
    @CurrentUser() user: any,
    @Param('workoutPlanId', ParseUUIDPipe) workoutPlanId: string,
  ): Promise<WorkoutPlanProgressDto> {
    return this.exerciseLogsService.getWorkoutPlanProgress(user.id, workoutPlanId);
  }

  @Get('workout-plan-progress/:userId/:workoutPlanId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get workout plan progress for a user' })
  @ApiResponse({ status: 200, description: 'Workout plan progress', type: WorkoutPlanProgressDto })
  getWorkoutPlanProgress(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Param('workoutPlanId', ParseUUIDPipe) workoutPlanId: string,
  ): Promise<WorkoutPlanProgressDto> {
    return this.exerciseLogsService.getWorkoutPlanProgress(userId, workoutPlanId);
  }

  @Get('workout-plans-progress/my')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get all workout plans progress for current user' })
  @ApiResponse({ status: 200, description: 'All workout plans progress', type: [WorkoutPlanProgressDto] })
  getMyWorkoutPlansProgress(@CurrentUser() user: any): Promise<WorkoutPlanProgressDto[]> {
    return this.exerciseLogsService.getUserWorkoutPlansProgress(user.id);
  }

  @Get('workout-plans-progress/:userId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get all workout plans progress for a user' })
  @ApiResponse({ status: 200, description: 'All workout plans progress', type: [WorkoutPlanProgressDto] })
  getUserWorkoutPlansProgress(
    @Param('userId', ParseUUIDPipe) userId: string,
  ): Promise<WorkoutPlanProgressDto[]> {
    return this.exerciseLogsService.getUserWorkoutPlansProgress(userId);
  }

  @Get('performance/my')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get exercise performance analytics for current user' })
  @ApiResponse({ status: 200, description: 'Exercise performance analytics', type: [ExercisePerformanceDto] })
  @ApiQuery({ name: 'exerciseId', required: false, description: 'Filter by specific exercise ID' })
  getMyExercisePerformance(
    @CurrentUser() user: any,
    @Query('exerciseId') exerciseId?: string,
  ): Promise<ExercisePerformanceDto[]> {
    return this.exerciseLogsService.getExercisePerformance(user.id, exerciseId);
  }

  @Get('performance/:userId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get exercise performance analytics for a user' })
  @ApiResponse({ status: 200, description: 'Exercise performance analytics', type: [ExercisePerformanceDto] })
  @ApiQuery({ name: 'exerciseId', required: false, description: 'Filter by specific exercise ID' })
  getExercisePerformance(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query('exerciseId') exerciseId?: string,
  ): Promise<ExercisePerformanceDto[]> {
    return this.exerciseLogsService.getExercisePerformance(userId, exerciseId);
  }

  @Get('streaks/my')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get exercise streaks for current user' })
  @ApiResponse({ status: 200, description: 'Exercise streaks information' })
  getMyExerciseStreaks(@CurrentUser() user: any) {
    return this.exerciseLogsService.getExerciseStreaks(user.id);
  }

  @Get('streaks/:userId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get exercise streaks for a user' })
  @ApiResponse({ status: 200, description: 'Exercise streaks information' })
  getExerciseStreaks(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.exerciseLogsService.getExerciseStreaks(userId);
  }


  // Get a WorkoutExerciseLog by ID
  // @Get('workout-exercise-logs/:id')
  // @UseGuards(RolesGuard)
  // @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  // @ApiOperation({ summary: 'Get a workout exercise log entry by ID' })
  // @ApiResponse({ status: 200, description: 'Workout exercise log details' })
  // findWorkoutExerciseLog(@Param('id', ParseUUIDPipe) id: string) {
  //   return this.exerciseLogsService.findWorkoutExerciseLogById(id);
  // }

  // List all set logs for a WorkoutExerciseLog
  @Get('workout-exercise-logs/:id/sets')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'List all set logs for a workout exercise log entry' })
  @ApiResponse({ status: 200, description: 'List of sets for the workout exercise log' })
  listSetsForWorkoutExerciseLog(@Param('id', ParseUUIDPipe) id: string) {
    return this.exerciseLogsService.listSetsByWorkoutExerciseLog(id);
  }

  // Daily Log CRUD for current user by date
  @Post('logs/my/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Create or update (upsert) daily log for current user' })
  upsertMyDailyLog(
    @CurrentUser() user: any,
    @Param('date') date: string,
    @Body() dto: UpdateDailyLogDto,
  ) {
    return this.exerciseLogsService.upsertDailyLog(user.id, date, dto);
  }

  @Get('logs/my/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get daily log for current user by date' })
  getMyDailyLog(@CurrentUser() user: any, @Param('date') date: string) {
    return this.exerciseLogsService.getDailyLog(user.id, date);
  }

  @Patch('logs/my/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Update daily log for current user' })
  updateMyDailyLog(
    @CurrentUser() user: any,
    @Param('date') date: string,
    @Body() dto: UpdateDailyLogDto,
  ) {
    return this.exerciseLogsService.updateDailyLog(user.id, date, dto);
  }

  @Delete('logs/my/:date')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Delete daily log for current user' })
  deleteMyDailyLog(@CurrentUser() user: any, @Param('date') date: string) {
    return this.exerciseLogsService.deleteDailyLog(user.id, date);
  }

  // Backward-compatible: treat exercise-logs/:id as WorkoutExerciseLog by ID
  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get a workout exercise log by ID' })
  @ApiResponse({ status: 200, description: 'Workout exercise log details' })
  @ApiResponse({ status: 404, description: 'Workout exercise log not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.exerciseLogsService.findWorkoutExerciseLogById(id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Update a workout exercise log (and its sets)' })
  @ApiResponse({ status: 200, description: 'Workout exercise log updated successfully' })
  @ApiResponse({ status: 404, description: 'Workout exercise log not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateExerciseLogDto,
  ) {
    return this.exerciseLogsService.updateWorkoutExerciseLog(id, dto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Delete a workout exercise log by ID' })
  @ApiResponse({ status: 200, description: 'Workout exercise log deleted successfully' })
  @ApiResponse({ status: 404, description: 'Workout exercise log not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.exerciseLogsService.deleteWorkoutExerciseLog(id);
  }



}
