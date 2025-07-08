import { IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateGymerDto {
  @ApiProperty({ example: 'user-uuid-here' })
  @IsUUID()
  userId: string;
}
