import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, IsOptional, IsNumber, IsDateString } from 'class-validator';

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
}

