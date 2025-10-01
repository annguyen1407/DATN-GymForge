import { IsUUID, IsString, IsOptional, IsEnum, IsNumber, IsUrl, IsBoolean } from 'class-validator';
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

  @ApiProperty({
    example: false,
    description: 'Whether this workout plan is a template that can be used by different roles',
    required: false,
    default: false
  })
  @IsOptional()
  @IsBoolean()
  isTemplate?: boolean;

  @ApiProperty({
    example: false,
    description: 'If true, cloning/using this template requires Premium (admins/coaches bypass)',
    required: false,
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  isPremiumOnly?: boolean;

  @ApiProperty({ example: 'training-request-uuid', required: false, description: 'Attach to an accepted training request (for visibility enforcement)' })
  @IsOptional()
  @IsUUID()
  trainingRequestId?: string;
}
