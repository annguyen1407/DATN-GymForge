import { IsOptional, IsString, IsEnum, IsDateString, IsNumber, IsUrl } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Gender, FitnessGoal } from '@prisma/client';

export class CreateUserProfileDto {
  @ApiProperty({ example: '+1234567890', required: false })
  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @ApiProperty({ example: '1990-01-01', required: false })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @ApiProperty({ enum: Gender, required: false })
  @IsOptional()
  @IsEnum(Gender)
  sex?: Gender;

  @ApiProperty({ example: '123 Main St, City, Country', required: false })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiProperty({ example: 70.5, required: false })
  @IsOptional()
  @IsNumber()
  weight?: number;

  @ApiProperty({ example: 175.0, required: false })
  @IsOptional()
  @IsNumber()
  height?: number;

  @ApiProperty({ enum: FitnessGoal, required: false })
  @IsOptional()
  @IsEnum(FitnessGoal)
  goal?: FitnessGoal;

  @ApiProperty({ example: 'Beginner', required: false })
  @IsOptional()
  @IsString()
  expType?: string;

  @ApiProperty({ example: 'Fitness enthusiast with 5 years of experience', required: false })
  @IsOptional()
  @IsString()
  biography?: string;

  @ApiProperty({ example: 'https://example.com/profile-picture.jpg', required: false })
  @IsOptional()
  @IsUrl()
  profilePicture?: string;
}
