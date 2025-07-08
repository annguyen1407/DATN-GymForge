import { Module } from '@nestjs/common';
import { GymersController } from './gymers.controller';
import { GymersService } from './gymers.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [GymersController],
  providers: [GymersService],
  exports: [GymersService],
})
export class GymersModule {}
