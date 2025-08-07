import { ApiProperty } from '@nestjs/swagger';

export class DeleteProfileResponseDto {
  @ApiProperty({ 
    description: 'Success message',
    example: 'User profile deleted successfully'
  })
  message: string;
}
