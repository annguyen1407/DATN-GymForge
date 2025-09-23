import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, IsOptional, IsNumber, IsDateString, IsEnum } from 'class-validator';

export enum WorkoutDayStatusDto {
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  SKIPPED = 'SKIPPED',
}

export class CreateWorkoutDayDto {
  @ApiProperty({ example: 'workout-plan-uuid-here' })
  @IsUUID()
  workoutPlanId: string;

  @ApiProperty({ example: 1, description: 'Day number in the workout plan', required: false })
  @IsOptional()
  @IsNumber()
  dayNumber?: number;

  @ApiProperty({ example: '2025-01-20', description: 'Scheduled calendar date (optional)', required: false })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiProperty({ enum: WorkoutDayStatusDto, required: false, description: 'Status of the workout day' })
  @IsOptional()
  @IsEnum(WorkoutDayStatusDto)
  status?: WorkoutDayStatusDto;

  @ApiProperty({ example: '2025-01-20T09:00:00Z', required: false, description: 'Timestamp when the day was completed' })
  @IsOptional()
  @IsDateString()
  completedAt?: string;
}
