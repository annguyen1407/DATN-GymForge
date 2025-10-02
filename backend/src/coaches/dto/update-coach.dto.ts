import { PartialType } from '@nestjs/swagger';
import { CreateCoachDto } from './create-coach.dto';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';
import { FitnessGoal } from '@prisma/client';

export class UpdateCoachDto extends PartialType(CreateCoachDto) {
  @ApiPropertyOptional({ description: 'Coach expertises (use FitnessGoal enum values)', isArray: true, enum: FitnessGoal })
  @IsOptional()
  @IsEnum(FitnessGoal, { each: true })
  expertises?: FitnessGoal[];
}
