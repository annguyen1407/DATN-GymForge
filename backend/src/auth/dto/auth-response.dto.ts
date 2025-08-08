import { ApiProperty } from '@nestjs/swagger';
import { User } from '@prisma/client';

export class AuthResponseDto {
  @ApiProperty()
  access_token: string;

  @ApiProperty()
  refresh_token: string;

  @ApiProperty()
  user: Partial<User>;

  @ApiProperty()
  expires_in: string | undefined;
}
