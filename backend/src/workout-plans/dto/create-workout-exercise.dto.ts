import { IsUUID, IsOptional, IsNumber } from 'class-validator';
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

  @ApiProperty({ example: 50.5, description: 'Weight in kg', required: false })
  @IsOptional()
  @IsNumber()
  weight?: number;
}
