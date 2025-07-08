import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MuscleGroup } from '@prisma/client';
import { CreateMuscleGroupDto } from './dto/create-muscle-group.dto';
import { UpdateMuscleGroupDto } from './dto/update-muscle-group.dto';

@Injectable()
export class MuscleGroupsService {
  constructor(private prisma: PrismaService) {}

  async create(createMuscleGroupDto: CreateMuscleGroupDto): Promise<MuscleGroup> {
    // Check if muscle group with this name already exists
    const existingMuscleGroup = await this.prisma.muscleGroup.findFirst({
      where: {
        name: {
          equals: createMuscleGroupDto.name,
          mode: 'insensitive',
        },
      },
    });

    if (existingMuscleGroup) {
      throw new ConflictException('Muscle group with this name already exists');
    }

    return this.prisma.muscleGroup.create({
      data: createMuscleGroupDto,
      include: {
        _count: {
          select: {
            exercises: true,
          },
        },
      },
    });
  }

  async findAll(): Promise<MuscleGroup[]> {
    return this.prisma.muscleGroup.findMany({
      include: {
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

  async findOne(id: string): Promise<MuscleGroup> {
    const muscleGroup = await this.prisma.muscleGroup.findUnique({
      where: { id },
      include: {
        exercises: {
          include: {
            exercise: {
              select: {
                id: true,
                name: true,
                description: true,
                defaultWeight: true,
                defaultSets: true,
                defaultReps: true,
              },
            },
          },
        },
        _count: {
          select: {
            exercises: true,
          },
        },
      },
    });

    if (!muscleGroup) {
      throw new NotFoundException('Muscle group not found');
    }

    return muscleGroup;
  }

  async update(id: string, updateMuscleGroupDto: UpdateMuscleGroupDto): Promise<MuscleGroup> {
    const muscleGroup = await this.findOne(id);

    // Check if another muscle group with this name already exists
    if (updateMuscleGroupDto.name) {
      const existingMuscleGroup = await this.prisma.muscleGroup.findFirst({
        where: {
          id: { not: id },
          name: {
            equals: updateMuscleGroupDto.name,
            mode: 'insensitive',
          },
        },
      });

      if (existingMuscleGroup) {
        throw new ConflictException('Muscle group with this name already exists');
      }
    }

    return this.prisma.muscleGroup.update({
      where: { id },
      data: updateMuscleGroupDto,
      include: {
        _count: {
          select: {
            exercises: true,
          },
        },
      },
    });
  }

  async remove(id: string): Promise<MuscleGroup> {
    const muscleGroup = await this.findOne(id);

    // Check if muscle group is being used by any exercises
    const exerciseCount = await this.prisma.exerciseMuscleGroup.count({
      where: { muscleGroupId: id },
    });

    if (exerciseCount > 0) {
      throw new ConflictException('Cannot delete muscle group that is being used by exercises');
    }

    return this.prisma.muscleGroup.delete({
      where: { id },
    });
  }

  async search(query: string): Promise<MuscleGroup[]> {
    return this.prisma.muscleGroup.findMany({
      where: {
        name: {
          contains: query,
          mode: 'insensitive',
        },
      },
      include: {
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
}
