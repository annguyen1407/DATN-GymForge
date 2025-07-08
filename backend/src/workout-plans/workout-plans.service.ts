import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WorkoutPlan, WorkoutExercise } from '@prisma/client';
import { CreateWorkoutPlanDto } from './dto/create-workout-plan.dto';
import { UpdateWorkoutPlanDto } from './dto/update-workout-plan.dto';
import { CreateWorkoutExerciseDto } from './dto/create-workout-exercise.dto';

@Injectable()
export class WorkoutPlansService {
  constructor(private prisma: PrismaService) {}

  async create(createWorkoutPlanDto: CreateWorkoutPlanDto): Promise<WorkoutPlan> {
    // Verify user exists
    const user = await this.prisma.user.findUnique({
      where: { id: createWorkoutPlanDto.userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.workoutPlan.create({
      data: createWorkoutPlanDto,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
        exercises: true,
      },
    });
  }

  async findAll(userId?: string): Promise<WorkoutPlan[]> {
    const where = userId ? { userId } : {};

    return this.prisma.workoutPlan.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
        exercises: true,
        _count: {
          select: {
            exercises: true,
          },
        },
      },
      orderBy: {
        name: 'asc',
      },
    });
  }

  async findOne(id: string): Promise<WorkoutPlan> {
    const workoutPlan = await this.prisma.workoutPlan.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
        exercises: {
          include: {
            appointments: true,
          },
        },
      },
    });

    if (!workoutPlan) {
      throw new NotFoundException('Workout plan not found');
    }

    return workoutPlan;
  }

  async findByUserId(userId: string): Promise<WorkoutPlan[]> {
    return this.prisma.workoutPlan.findMany({
      where: { userId },
      include: {
        exercises: true,
        _count: {
          select: {
            exercises: true,
          },
        },
      },
      orderBy: {
        name: 'asc',
      },
    });
  }

  async update(id: string, updateWorkoutPlanDto: UpdateWorkoutPlanDto, currentUserId?: string): Promise<WorkoutPlan> {
    const workoutPlan = await this.findOne(id);

    // Check if user owns this workout plan or is admin
    if (currentUserId && workoutPlan.userId !== currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
      });
      if (user?.role !== 'ADMIN') {
        throw new ForbiddenException('You can only update your own workout plans');
      }
    }

    return this.prisma.workoutPlan.update({
      where: { id },
      data: updateWorkoutPlanDto,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
        exercises: true,
      },
    });
  }

  async remove(id: string, currentUserId?: string): Promise<WorkoutPlan> {
    const workoutPlan = await this.findOne(id);

    // Check if user owns this workout plan or is admin
    if (currentUserId && workoutPlan.userId !== currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
      });
      if (user?.role !== 'ADMIN') {
        throw new ForbiddenException('You can only delete your own workout plans');
      }
    }

    return this.prisma.workoutPlan.delete({
      where: { id },
    });
  }

  // Workout Exercise methods
  async addExercise(createWorkoutExerciseDto: CreateWorkoutExerciseDto): Promise<WorkoutExercise> {
    // Verify workout plan exists
    const workoutPlan = await this.prisma.workoutPlan.findUnique({
      where: { id: createWorkoutExerciseDto.workoutPlanId },
    });

    if (!workoutPlan) {
      throw new NotFoundException('Workout plan not found');
    }

    return this.prisma.workoutExercise.create({
      data: createWorkoutExerciseDto,
      include: {
        workoutPlan: true,
      },
    });
  }

  async removeExercise(workoutExerciseId: string): Promise<WorkoutExercise> {
    const workoutExercise = await this.prisma.workoutExercise.findUnique({
      where: { id: workoutExerciseId },
    });

    if (!workoutExercise) {
      throw new NotFoundException('Workout exercise not found');
    }

    return this.prisma.workoutExercise.delete({
      where: { id: workoutExerciseId },
    });
  }

  async updateExercise(workoutExerciseId: string, updateData: Partial<CreateWorkoutExerciseDto>): Promise<WorkoutExercise> {
    const workoutExercise = await this.prisma.workoutExercise.findUnique({
      where: { id: workoutExerciseId },
    });

    if (!workoutExercise) {
      throw new NotFoundException('Workout exercise not found');
    }

    return this.prisma.workoutExercise.update({
      where: { id: workoutExerciseId },
      data: updateData,
      include: {
        workoutPlan: true,
      },
    });
  }
}
