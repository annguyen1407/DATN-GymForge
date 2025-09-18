import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, IsOptional, IsNumber, IsString, IsArray, ValidateNested, Min, ArrayMinSize } from 'class-validator';
import { Type } from 'class-transformer';

export class QuickSetDto {
  @ApiProperty({ description: 'Number of repetitions', example: 12 })
  @IsNumber()
  @Min(0)
  reps: number;

  @ApiProperty({ description: 'Weight used in kg', example: 50.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;

  @ApiProperty({ description: 'Time duration in seconds', example: 60 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  duration?: number;
}

export class QuickLogExerciseDto {
  @ApiProperty({ description: 'WorkoutExercise ID when logging against a planned workout', required: true, example: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' })
  @IsUUID()
  workoutExerciseId: string;

  @ApiProperty({ description: 'Workout plan ID if part of a plan', required: false })
  @IsOptional()
  @IsUUID()
  workoutPlanId?: string;

  @ApiProperty({ description: 'Day number in the workout plan', required: false })
  @IsOptional()
  @IsNumber()
  @Min(1)
  dayNumber?: number;

  @ApiProperty({ description: 'Array of sets performed', type: [QuickSetDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => QuickSetDto)
  sets: QuickSetDto[];

  @ApiProperty({ description: 'Additional notes', required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}
