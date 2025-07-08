import { IsUUID, IsOptional, IsString, IsNumber, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateFeedbackDto {
  @ApiProperty({ example: 'gymer-uuid-here' })
  @IsUUID()
  gymerId: string;

  @ApiProperty({ example: 'coach-uuid-here' })
  @IsUUID()
  coachId: string;

  @ApiProperty({ example: 4.5, minimum: 1, maximum: 5, required: false })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  rating?: number;

  @ApiProperty({ example: 'Great coach! Very knowledgeable and motivating.', required: false })
  @IsOptional()
  @IsString()
  content?: string;
}
