import { IsUUID, IsString, IsOptional, IsEnum, IsNumber, IsUrl } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PlanType, PlanStatus } from '@prisma/client';

export class CreateWorkoutPlanDto {
  @ApiProperty({ example: 'user-uuid-here' })
  @IsUUID()
  userId: string;

  @ApiProperty({ example: 'Full Body Strength Training' })
  @IsString()
  name: string;

  @ApiProperty({ example: 'A comprehensive full body workout plan for beginners', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 'https://example.com/workout-plan-image.jpg', required: false })
  @IsOptional()
  @IsUrl()
  picture?: string;

  @ApiProperty({ enum: PlanType, example: PlanType.STRENGTH })
  @IsEnum(PlanType)
  planType: PlanType;

  @ApiProperty({ enum: PlanStatus, default: PlanStatus.ACTIVE, required: false })
  @IsOptional()
  @IsEnum(PlanStatus)
  status?: PlanStatus;

  @ApiProperty({ example: 30, description: 'Duration of the plan in days', required: false })
  @IsOptional()
  @IsNumber()
  days?: number;
}
