import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Exercise } from '@prisma/client';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';

@Injectable()
export class ExercisesService {
  constructor(private prisma: PrismaService) {}

  async create(createExerciseDto: CreateExerciseDto): Promise<Exercise> {
    const { muscleGroupIds, ...exerciseData } = createExerciseDto;

    // Create exercise
    const exercise = await this.prisma.exercise.create({
      data: exerciseData,
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
        muscleGroups: {
          include: {
            muscleGroup: true,
          },
        },
      },
    });

    // Add muscle group relationships if provided
    if (muscleGroupIds && muscleGroupIds.length > 0) {
      await this.prisma.exerciseMuscleGroup.createMany({
        data: muscleGroupIds.map(muscleGroupId => ({
          exerciseId: exercise.id,
          muscleGroupId,
        })),
      });
    }

    return this.findOne(exercise.id);
  }

  async findAll(userId?: string): Promise<Exercise[]> {
    const where = userId ? { OR: [{ userId }, { userId: null }] } : {};

    return this.prisma.exercise.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
        muscleGroups: {
          include: {
            muscleGroup: true,
          },
        },
      },
      orderBy: {
        name: 'asc',
      },
    });
  }

  async findOne(id: string): Promise<Exercise> {
    const exercise = await this.prisma.exercise.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
        muscleGroups: {
          include: {
            muscleGroup: true,
          },
        },
      },
    });

    if (!exercise) {
      throw new NotFoundException('Exercise not found');
    }

    return exercise;
  }

  async findByMuscleGroup(muscleGroupId: string): Promise<Exercise[]> {
    return this.prisma.exercise.findMany({
      where: {
        muscleGroups: {
          some: {
            muscleGroupId,
          },
        },
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
        muscleGroups: {
          include: {
            muscleGroup: true,
          },
        },
      },
      orderBy: {
        name: 'asc',
      },
    });
  }

  async update(id: string, updateExerciseDto: UpdateExerciseDto): Promise<Exercise> {
    const { muscleGroupIds, ...exerciseData } = updateExerciseDto;
    
    const exercise = await this.findOne(id);

    // Update exercise data
    await this.prisma.exercise.update({
      where: { id },
      data: exerciseData,
    });

    // Update muscle group relationships if provided
    if (muscleGroupIds !== undefined) {
      // Remove existing relationships
      await this.prisma.exerciseMuscleGroup.deleteMany({
        where: { exerciseId: id },
      });

      // Add new relationships
      if (muscleGroupIds.length > 0) {
        await this.prisma.exerciseMuscleGroup.createMany({
          data: muscleGroupIds.map(muscleGroupId => ({
            exerciseId: id,
            muscleGroupId,
          })),
        });
      }
    }

    return this.findOne(id);
  }

  async remove(id: string): Promise<Exercise> {
    const exercise = await this.findOne(id);

    // Remove muscle group relationships first
    await this.prisma.exerciseMuscleGroup.deleteMany({
      where: { exerciseId: id },
    });

    return this.prisma.exercise.delete({
      where: { id },
    });
  }

  async search(query: string): Promise<Exercise[]> {
    return this.prisma.exercise.findMany({
      where: {
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
          { instruction: { contains: query, mode: 'insensitive' } },
        ],
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
        muscleGroups: {
          include: {
            muscleGroup: true,
          },
        },
      },
      orderBy: {
        name: 'asc',
      },
    });
  }
}
