import { IsUUID, IsOptional, IsISO8601 } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateTrainingRequestDto {
  @ApiProperty({ example: 'gymer-uuid-here' })
  @IsUUID()
  gymerId: string;

  @ApiProperty({ example: 'coach-uuid-here' })
  @IsUUID()
  coachId: string;

  @ApiProperty({ example: '2025-11-15T10:00:00.000Z', required: false, description: 'Planned training date/time (ISO-8601)' })
  @IsOptional()
  @IsISO8601()
  trainingDate?: string;
}
