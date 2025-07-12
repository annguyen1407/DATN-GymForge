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
import { WorkoutPlansService } from './workout-plans.service';
import { CreateWorkoutPlanDto } from './dto/create-workout-plan.dto';
import { UpdateWorkoutPlanDto } from './dto/update-workout-plan.dto';
import { CreateWorkoutExerciseDto } from './dto/create-workout-exercise.dto';
import { CreateFromTemplateDto } from './dto/create-from-template.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

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
  findAll(@Query('userId') userId?: string) {
    return this.workoutPlansService.findAll(userId);
  }

  @Get('templates')
  @ApiOperation({ summary: 'Get all workout plan templates' })
  @ApiResponse({ status: 200, description: 'List of all workout plan templates' })
  @ApiQuery({ name: 'planType', required: false, description: 'Filter templates by plan type' })
  findTemplates(@Query('planType') planType?: string, @CurrentUser() user?: any) {
    return this.workoutPlansService.findTemplates(planType, user?.id);
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
  findByUserId(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.workoutPlansService.findByUserId(userId);
  }

  @Post('from-template/:templateId')
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

  @Get(':id')
  @ApiOperation({ summary: 'Get a workout plan by ID' })
  @ApiResponse({ status: 200, description: 'Workout plan details' })
  @ApiResponse({ status: 404, description: 'Workout plan not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.workoutPlansService.findOne(id);
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

  // Workout Exercise endpoints
  @Post('exercises')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Add exercise to workout plan' })
  @ApiResponse({ status: 201, description: 'Exercise added to workout plan successfully' })
  addExercise(@Body() createWorkoutExerciseDto: CreateWorkoutExerciseDto) {
    return this.workoutPlansService.addExercise(createWorkoutExerciseDto);
  }

  @Delete('exercises/:exerciseId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Remove exercise from workout plan' })
  @ApiResponse({ status: 200, description: 'Exercise removed from workout plan successfully' })
  removeExercise(@Param('exerciseId', ParseUUIDPipe) exerciseId: string) {
    return this.workoutPlansService.removeExercise(exerciseId);
  }

  @Patch('exercises/:exerciseId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Update exercise in workout plan' })
  @ApiResponse({ status: 200, description: 'Exercise updated successfully' })
  updateExercise(
    @Param('exerciseId', ParseUUIDPipe) exerciseId: string,
    @Body() updateData: Partial<CreateWorkoutExerciseDto>,
  ) {
    return this.workoutPlansService.updateExercise(exerciseId, updateData);
  }
}
