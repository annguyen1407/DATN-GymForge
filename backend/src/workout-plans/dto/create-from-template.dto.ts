import { IsUUID, IsString, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateFromTemplateDto {
  @ApiProperty({ example: 'user-uuid-here' })
  @IsUUID()
  userId: string;

  @ApiProperty({ example: 'My Custom Workout Plan', required: false })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({ example: 'A personalized workout plan based on template', required: false })
  @IsOptional()
  @IsString()
  description?: string;
}
