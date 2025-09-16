import { IsUUID, IsOptional, IsNumber, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateWorkoutExerciseDto {
  @ApiProperty({ example: 'workout-plan-uuid-here', required: false })
  @IsOptional()
  @IsUUID()
  workoutPlanId?: string;

  @ApiProperty({ example: 'workout-day-uuid-here', required: false, description: 'Preferred: attach directly to a day' })
  @IsOptional()
  @IsUUID()
  workoutDayId?: string;

  @ApiProperty({ example: 'exercise-uuid-here', required: true })
  @IsUUID()
  exerciseId: string;

  @ApiProperty({ example: 1, description: 'Day number in the workout plan (legacy path)', required: false })
  @IsOptional()
  @IsNumber()
  dayNumber?: number;

  // Planned overrides; if omitted, defaults will be taken from Exercise
  @ApiProperty({ example: 4, required: false })
  @IsOptional()
  @IsNumber()
  targetSets?: number;

  @ApiProperty({ example: 12, required: false })
  @IsOptional()
  @IsNumber()
  targetReps?: number;

  @ApiProperty({ example: 50.5, description: 'Target weight in kg', required: false })
  @IsOptional()
  @IsNumber()
  targetWeight?: number;

  @ApiProperty({ example: 60, description: 'Rest time in seconds', required: false })
  @IsOptional()
  @IsNumber()
  restTimeSec?: number;

  @ApiProperty({ example: 45, description: 'Time per set in seconds', required: false })
  @IsOptional()
  @IsNumber()
  timePerSetSec?: number;

  @ApiProperty({ example: 1, description: 'Ordering within the day', required: false })
  @IsOptional()
  @IsNumber()
  order?: number;

  @ApiProperty({ example: 'Keep back straight', required: false })
  @IsOptional()
  @IsString()
  notes?: string;

}
