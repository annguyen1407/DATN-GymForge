import { IsUUID, IsString, IsOptional, IsNumber, IsUrl, IsArray } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateExerciseDto {
  @ApiProperty({ example: 'user-uuid-here', required: false })
  @IsOptional()
  @IsUUID()
  userId?: string;

  @ApiProperty({ example: 'Push-ups' })
  @IsString()
  name: string;

  @ApiProperty({ example: 'equipment-uuid-here', required: false })
  @IsOptional()
  @IsUUID()
  equipmentId?: string;

  @ApiProperty({ example: 'A basic upper body exercise that targets chest, shoulders, and triceps', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 'Start in plank position, lower body to ground, push back up', required: false })
  @IsOptional()
  @IsString()
  instruction?: string;

  @ApiProperty({ example: 'https://example.com/pushup-video.mp4', required: false })
  @IsOptional()
  @IsUrl()
  videoUrl?: string;

  @ApiProperty({ example: 3.5, description: 'Metabolic equivalent of task', required: false })
  @IsOptional()
  @IsNumber()
  met?: number;

  @ApiProperty({ example: 0, description: 'Default weight in kg', required: false })
  @IsOptional()
  @IsNumber()
  defaultWeight?: number;

  @ApiProperty({ example: 3, description: 'Default number of sets', required: false })
  @IsOptional()
  @IsNumber()
  defaultSets?: number;

  @ApiProperty({ example: 15, description: 'Default reps per set', required: false })
  @IsOptional()
  @IsNumber()
  defaultReps?: number;

  @ApiProperty({ example: 60, description: 'Rest time between sets in seconds', required: false })
  @IsOptional()
  @IsNumber()
  restTime?: number;

  @ApiProperty({ example: ['muscle-group-uuid-1', 'muscle-group-uuid-2'], required: false })
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  muscleGroupIds?: string[];
}
