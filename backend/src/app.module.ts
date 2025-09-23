import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { CoachesModule } from './coaches/coaches.module';
import { GymersModule } from './gymers/gymers.module';
import { WorkoutPlansModule } from './workout-plans/workout-plans.module';
import { ExercisesModule } from './exercises/exercises.module';
import { AppointmentsModule } from './appointments/appointments.module';
import { TrainingRequestsModule } from './training-requests/training-requests.module';
import { FeedbacksModule } from './feedbacks/feedbacks.module';
import { MuscleGroupsModule } from './muscle-groups/muscle-groups.module';
import { EquipmentModule } from './equipment/equipment.module';
import { EmailModule } from './email/email.module';
import { UserProfileModule } from './user-profile/user-profile.module';
import { ExerciseLogsModule } from './exercise-logs/exercise-logs.module';
import { MealsModule } from './meals/meals.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    PrismaModule,
    AuthModule,
    CoachesModule,
    GymersModule,
    WorkoutPlansModule,
    ExercisesModule,
    AppointmentsModule,
    TrainingRequestsModule,
    FeedbacksModule,
    MuscleGroupsModule,
    EquipmentModule,
    EmailModule,
    UserProfileModule,
    ExerciseLogsModule,
    MealsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
