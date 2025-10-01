import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, Min, Max } from 'class-validator';

export class UpdateAdminConfigDto {
  @ApiPropertyOptional({ description: 'Base price X (>= 0)', example: 10 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  basePriceX?: number;

  @ApiPropertyOptional({ description: 'Rating multiplier in [0,1]', example: 0.2 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1)
  ratingMultiplier?: number;

  @ApiPropertyOptional({ description: 'Commission rate in [0,1]', example: 0.1 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1)
  commissionRate?: number;

  @ApiPropertyOptional({ description: 'Coach cancel lock window in days (>= 0)', example: 30 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  coachCancelLockDays?: number;
}

