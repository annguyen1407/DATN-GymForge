import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsNumber, IsOptional } from 'class-validator';
import { Transform } from 'class-transformer';

export class ListCoachesQueryDto {
  @ApiPropertyOptional({ enum: ['price', 'rating', 'name', 'recommended'], description: 'Sort by: price, rating, name, or recommended (score-based)' })
  @IsOptional()
  @IsIn(['price', 'rating', 'name', 'recommended'])
  sortBy?: 'price' | 'rating' | 'name' | 'recommended';

  @ApiPropertyOptional({ enum: ['asc', 'desc'], default: 'asc' })
  @IsOptional()
  @IsIn(['asc', 'desc'])
  sortOrder?: 'asc' | 'desc';

  @ApiPropertyOptional({ type: Number, description: 'Minimum trainingPrice filter' })
  @IsOptional()
  @Transform(({ value }) => (value !== undefined ? parseFloat(value) : undefined))
  @IsNumber()
  minPrice?: number;

  @ApiPropertyOptional({ type: Number, description: 'Maximum trainingPrice filter' })
  @IsOptional()
  @Transform(({ value }) => (value !== undefined ? parseFloat(value) : undefined))
  @IsNumber()
  maxPrice?: number;

  @ApiPropertyOptional({ type: Boolean, description: 'Filter coaches who are open to training' })
  @IsOptional()
  @Transform(({ value }) => (value === 'true' || value === true ? true : value === 'false' || value === false ? false : undefined))
  @IsBoolean()
  isOpenToTraining?: boolean;
}
