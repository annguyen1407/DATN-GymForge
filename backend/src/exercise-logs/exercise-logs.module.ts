import { Module } from '@nestjs/common';
import { ExerciseLogsController } from './exercise-logs.controller';
import { ExerciseLogsService } from './exercise-logs.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ExerciseLogsController],
  providers: [ExerciseLogsService],
  exports: [ExerciseLogsService],
})
export class ExerciseLogsModule {}
