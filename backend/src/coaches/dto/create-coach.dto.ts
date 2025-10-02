import { IsUUID, IsOptional, IsString, IsNumber, IsArray, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { FitnessGoal } from '@prisma/client';

export class CreateCoachDto {
  @ApiProperty({ example: 'user-uuid-here' })
  @IsUUID()
  userId: string;

  @ApiProperty({ example: 'NASM Certified Personal Trainer', required: false })
  @IsOptional()
  @IsString()
  certification?: string;

  @ApiProperty({ example: 'Active', required: false })
  @IsOptional()
  @IsString()
  status?: string;

  @ApiProperty({ description: 'Coach expertises (use FitnessGoal enum values)', isArray: true, enum: FitnessGoal, required: false })
  @IsOptional()
  @IsEnum(FitnessGoal, { each: true })
  expertises?: FitnessGoal[];
}
