import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';
import { MealType } from '@prisma/client';

export class UpdateMealDto {
  @ApiPropertyOptional({ example: 'Grilled Fish' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ example: 420 })
  @IsNumber()
  @IsOptional()
  calories?: number;

  @ApiPropertyOptional({ enum: MealType, example: MealType.DINNER })
  @IsEnum(MealType)
  @IsOptional()
  type?: MealType;
}

