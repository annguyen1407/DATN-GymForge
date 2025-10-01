import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { PaymentMethod } from '@prisma/client';

export class PurchaseSubscriptionDto {
  @ApiProperty({ description: 'Subscription plan ID', format: 'uuid' })
  @IsUUID()
  planId: string;

  @ApiProperty({ enum: PaymentMethod, default: PaymentMethod.MOMO })
  @IsEnum(PaymentMethod)
  method: PaymentMethod;

  @ApiProperty({ required: false, description: 'Payment provider token or reference' })
  @IsOptional()
  @IsString()
  providerToken?: string;
}

