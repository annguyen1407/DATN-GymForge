import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateDailyLogDto {
  @ApiPropertyOptional({ description: 'Notes for the day' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ description: 'Calories burned for the day (manual override/addition)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  caloriesBurned?: number;

  @ApiPropertyOptional({ description: 'Calories intake for the day (sum of meals or manual input)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  caloriesIntake?: number;

  @ApiPropertyOptional({ description: 'Body weight (kg) recorded on the day' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;

  @ApiPropertyOptional({ description: 'Body height (cm) recorded on the day' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  height?: number;
}

