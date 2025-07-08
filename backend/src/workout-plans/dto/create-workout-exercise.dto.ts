import { IsUUID, IsOptional, IsNumber } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateWorkoutExerciseDto {
  @ApiProperty({ example: 'workout-plan-uuid-here' })
  @IsUUID()
  workoutPlanId: string;

  @ApiProperty({ example: 'exercise-uuid-here', required: false })
  @IsOptional()
  @IsUUID()
  exerciseId?: string;

  @ApiProperty({ example: 1, description: 'Day number in the workout plan', required: false })
  @IsOptional()
  @IsNumber()
  dayNumber?: number;

  @ApiProperty({ example: 50.5, description: 'Weight in kg', required: false })
  @IsOptional()
  @IsNumber()
  weight?: number;
}
