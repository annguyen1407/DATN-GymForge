import { IsUUID, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { TrainingRequestStatus } from '@prisma/client';

export class CreateTrainingRequestDto {
  @ApiProperty({ example: 'gymer-uuid-here' })
  @IsUUID()
  gymerId: string;

  @ApiProperty({ example: 'coach-uuid-here' })
  @IsUUID()
  coachId: string;

  @ApiProperty({ enum: TrainingRequestStatus, default: TrainingRequestStatus.PENDING, required: false })
  @IsOptional()
  @IsEnum(TrainingRequestStatus)
  status?: TrainingRequestStatus;
}
