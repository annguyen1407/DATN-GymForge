import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsNumber, IsOptional, IsPositive, IsString, Min } from 'class-validator';

export class CreateSubscriptionPlanDto {
  @ApiProperty({ example: 'Premium 1 Month' })
  @IsString()
  name: string;

  @ApiProperty({ example: 1, description: 'Duration in months' })
  @IsInt()
  @Min(1)
  durationMonths: number;

  @ApiProperty({ example: 100000 })
  @IsNumber()
  @IsPositive()
  price: number;

  @ApiProperty({ example: 'VND', required: false })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiProperty({ example: true, required: false })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

