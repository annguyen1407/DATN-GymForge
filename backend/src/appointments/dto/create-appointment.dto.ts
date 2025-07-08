import { IsUUID, IsOptional, IsString, IsDateString, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { AppointmentStatus } from '@prisma/client';

export class CreateAppointmentDto {
  @ApiProperty({ example: 'gymer-uuid-here' })
  @IsUUID()
  gymerId: string;

  @ApiProperty({ example: 'coach-uuid-here' })
  @IsUUID()
  coachId: string;

  @ApiProperty({ example: '2024-01-15T10:00:00Z', required: false })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiProperty({ example: 'workout-exercise-uuid-here', required: false })
  @IsOptional()
  @IsUUID()
  workoutExerciseId?: string;

  @ApiProperty({ example: 'Focus on proper form for squats', required: false })
  @IsOptional()
  @IsString()
  note?: string;

  @ApiProperty({ enum: AppointmentStatus, default: AppointmentStatus.PENDING, required: false })
  @IsOptional()
  @IsEnum(AppointmentStatus)
  status?: AppointmentStatus;

  @ApiProperty({ example: 'Gym Floor A, Section 2', required: false })
  @IsOptional()
  @IsString()
  location?: string;
}
