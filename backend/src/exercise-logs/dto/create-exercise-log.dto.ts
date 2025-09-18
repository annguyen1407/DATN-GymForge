import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, IsOptional, IsNumber, IsDateString, IsString, IsArray, ValidateNested, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateSetLogDto {
  @ApiProperty({ description: 'Set number in the exercise', example: 1 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  setNumber?: number;

  @ApiProperty({ description: 'Number of repetitions', example: 12 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  reps?: number;

  @ApiProperty({ description: 'Time duration in seconds', example: 60 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  times?: number;

  @ApiProperty({ description: 'Weight used in kg', example: 50.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;

  @ApiProperty({ description: 'Calories burned in this set', example: 15.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  caloriesBurned?: number;
}

export class CreateExerciseLogDto {
  @ApiProperty({ description: 'User ID who performed the exercise' })
  @IsUUID()
  userId: string;


  @ApiProperty({ description: 'Workout plan ID if part of a plan', required: false, example: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' })
  @IsOptional()
  @IsUUID()
  workoutPlanId?: string;


  @ApiProperty({ description: 'WorkoutExercise ID to log against a planned workout', required: true, example: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' })
  @IsUUID()
  workoutExerciseId: string;

  @ApiProperty({ description: 'Day number in the workout plan', required: false })
  @IsOptional()
  @IsNumber()
  @Min(1)
  dayNumber?: number;

  @ApiProperty({ description: 'Date when the exercise was performed', example: '2024-01-15' })
  @IsDateString()
  date: string;

  @ApiProperty({ description: 'Exercise name if custom exercise' })
  @IsOptional()
  @IsString()
  exerciseName?: string;

  @ApiProperty({ description: 'Total calories burned in the exercise', example: 150.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  totalCaloriesBurned?: number;

  @ApiProperty({ description: 'Progress percentage for the workout plan', example: 75.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  progressPercent?: number;

  @ApiProperty({ description: 'Additional notes about the exercise session' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ description: 'Array of sets performed in this exercise', type: [CreateSetLogDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSetLogDto)
  sets?: CreateSetLogDto[];
}
