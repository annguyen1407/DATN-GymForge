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
import { ExercisesService } from './exercises.service';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';
import { ExerciseLogsService } from '../exercise-logs/exercise-logs.service';

@ApiTags('exercises')
@Controller('exercises')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ExercisesController {
  constructor(
    private readonly exercisesService: ExercisesService,
    private readonly exerciseLogsService: ExerciseLogsService,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Create a new exercise' })
  @ApiResponse({ status: 201, description: 'Exercise created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  create(@Body() createExerciseDto: CreateExerciseDto) {
    return this.exercisesService.create(createExerciseDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all exercises' })
  @ApiResponse({ status: 200, description: 'List of all exercises' })
  @ApiQuery({ name: 'userId', required: false, description: 'Filter by user ID' })
  @ApiQuery({ name: 'search', required: false, description: 'Search exercises' })
  findAll(@Query('userId') userId?: string, @Query('search') search?: string) {
    if (search) {
      return this.exercisesService.search(search);
    }
    return this.exercisesService.findAll(userId);
  }

  @Get('muscle-group/:muscleGroupId')
  @ApiOperation({ summary: 'Get exercises by muscle group' })
  @ApiResponse({ status: 200, description: 'Exercises for muscle group' })
  findByMuscleGroup(@Param('muscleGroupId', ParseUUIDPipe) muscleGroupId: string) {
    return this.exercisesService.findByMuscleGroup(muscleGroupId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get an exercise by ID' })
  @ApiResponse({ status: 200, description: 'Exercise details' })
  @ApiResponse({ status: 404, description: 'Exercise not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.exercisesService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Update an exercise' })
  @ApiResponse({ status: 200, description: 'Exercise updated successfully' })
  @ApiResponse({ status: 404, description: 'Exercise not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateExerciseDto: UpdateExerciseDto,
  ) {
    return this.exercisesService.update(id, updateExerciseDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Delete an exercise' })
  @ApiResponse({ status: 200, description: 'Exercise deleted successfully' })
  @ApiResponse({ status: 404, description: 'Exercise not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.exercisesService.remove(id);
  }

  @Get(':id/performance/:userId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get performance analytics for a specific exercise and user' })
  @ApiResponse({ status: 200, description: 'Exercise performance analytics' })
  getExercisePerformance(
    @Param('id', ParseUUIDPipe) exerciseId: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.exerciseLogsService.getExercisePerformance(userId, exerciseId);
  }

  @Get(':id/performance/my')
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER, UserRole.COACH)
  @ApiOperation({ summary: 'Get performance analytics for a specific exercise for current user' })
  @ApiResponse({ status: 200, description: 'Exercise performance analytics' })
  getMyExercisePerformance(
    @Param('id', ParseUUIDPipe) exerciseId: string,
    @CurrentUser() user: any,
  ) {
    return this.exerciseLogsService.getExercisePerformance(user.id, exerciseId);
  }
}
