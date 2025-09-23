import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';
import { MealType } from '@prisma/client';

export class AddMealForDayDto {
  @ApiProperty({ example: 'Chicken Salad' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 350 })
  @IsNumber()
  calories: number;

  @ApiPropertyOptional({ enum: MealType, example: MealType.LUNCH })
  @IsEnum(MealType)
  @IsOptional()
  type?: MealType;
}

