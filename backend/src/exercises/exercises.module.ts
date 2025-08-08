import { Module } from '@nestjs/common';
import { ExercisesController } from './exercises.controller';
import { ExercisesService } from './exercises.service';
import { PrismaModule } from '../prisma/prisma.module';
import { ExerciseLogsModule } from '../exercise-logs/exercise-logs.module';

@Module({
  imports: [PrismaModule, ExerciseLogsModule],
  controllers: [ExercisesController],
  providers: [ExercisesService],
  exports: [ExercisesService],
})
export class ExercisesModule {}
