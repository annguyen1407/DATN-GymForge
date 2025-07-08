import { IsUUID, IsOptional, IsString, IsNumber } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

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
}
