import { Module } from '@nestjs/common';
import { SalariesController } from './salaries.controller';
import { SalariesService } from './salaries.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [SalariesController],
  providers: [SalariesService],
})
export class SalariesModule {}

