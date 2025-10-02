import { IsUUID, IsOptional, IsISO8601 } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateTrainingRequestDto {
  @ApiPropertyOptional({ example: 'gymer-uuid-here', description: 'If not provided, pass gymerUserId instead' })
  @IsOptional()
  @IsUUID()
  gymerId?: string;

  @ApiPropertyOptional({ example: 'coach-uuid-here', description: 'If not provided, pass coachUserId instead' })
  @IsOptional()
  @IsUUID()
  coachId?: string;

  @ApiPropertyOptional({ example: 'gymer-user-uuid-here' })
  @IsOptional()
  @IsUUID()
  gymerUserId?: string;

  @ApiPropertyOptional({ example: 'coach-user-uuid-here' })
  @IsOptional()
  @IsUUID()
  coachUserId?: string;

  @ApiProperty({ example: '2025-11-15T10:00:00.000Z', required: false, description: 'Planned training date/time (ISO-8601)' })
  @IsOptional()
  @IsISO8601()
  trainingDate?: string;
}
