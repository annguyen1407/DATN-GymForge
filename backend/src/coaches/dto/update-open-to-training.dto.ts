import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class UpdateOpenToTrainingDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  isOpenToTraining!: boolean;
}

