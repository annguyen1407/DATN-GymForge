import { IsString, IsOptional, IsUrl } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateEquipmentDto {
  @ApiProperty({ example: 'Treadmill Pro X1' })
  @IsString()
  name: string;

  @ApiProperty({ example: 'https://example.com/equipment-image.jpg', required: false })
  @IsOptional()
  @IsUrl()
  picture?: string;
}
