import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateMuscleGroupDto {
  @ApiProperty({ example: 'Chest' })
  @IsString()
  name: string;
}
