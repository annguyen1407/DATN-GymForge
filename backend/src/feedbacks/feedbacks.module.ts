import { Module } from '@nestjs/common';
import { FeedbacksController } from './feedbacks.controller';
import { FeedbacksService } from './feedbacks.service';
import { PrismaModule } from '../prisma/prisma.module';
import { CoachesModule } from '../coaches/coaches.module';

@Module({
  imports: [PrismaModule, CoachesModule],
  controllers: [FeedbacksController],
  providers: [FeedbacksService],
  exports: [FeedbacksService],
})
export class FeedbacksModule {}
