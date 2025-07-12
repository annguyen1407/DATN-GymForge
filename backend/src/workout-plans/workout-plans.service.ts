import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WorkoutPlan, WorkoutExercise } from '@prisma/client';
import { CreateWorkoutPlanDto } from './dto/create-workout-plan.dto';
import { UpdateWorkoutPlanDto } from './dto/update-workout-plan.dto';
import { CreateWorkoutExerciseDto } from './dto/create-workout-exercise.dto';

@Injectable()
export class WorkoutPlansService {
  constructor(private prisma: PrismaService) {}

  async create(createWorkoutPlanDto: CreateWorkoutPlanDto, currentUserId?: string): Promise<WorkoutPlan> {
    // Verify user exists
    const user = await this.prisma.user.findUnique({
      where: { id: createWorkoutPlanDto.userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check permissions: users can only create plans for themselves unless they're admin/coach
    if (currentUserId && currentUserId !== createWorkoutPlanDto.userId) {
      const currentUser = await this.prisma.user.findUnique({
        where: { id: currentUserId },
      });

      if (!currentUser || !currentUser.role || !['ADMIN', 'COACH'].includes(currentUser.role)) {
        throw new ForbiddenException('You can only create workout plans for yourself');
      }
    }

    // Only ADMIN and COACH can create templates
    if (createWorkoutPlanDto.isTemplate && currentUserId) {
      const currentUser = await this.prisma.user.findUnique({
        where: { id: currentUserId },
      });

      if (!currentUser || !currentUser.role || !['ADMIN', 'COACH'].includes(currentUser.role)) {
        throw new ForbiddenException('Only admins and coaches can create templates');
      }
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
    const where = userId ? { userId, isTemplate: false } : { isTemplate: false };

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

  async findTemplates(planType?: string, currentUserId?: string): Promise<WorkoutPlan[]> {
    const where: any = { isTemplate: true };
    if (planType) {
      where.planType = planType;
    }

    return this.prisma.workoutPlan.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            role: true,
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

  async findTemplatesByCreator(creatorId: string): Promise<WorkoutPlan[]> {
    return this.prisma.workoutPlan.findMany({
      where: {
        userId: creatorId,
        isTemplate: true
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            role: true,
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
      where: { userId, isTemplate: false },
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

  async createFromTemplate(
    templateId: string,
    createData: { userId: string; name?: string; description?: string },
    currentUserId?: string
  ): Promise<WorkoutPlan> {
    // Find the template
    const template = await this.prisma.workoutPlan.findUnique({
      where: { id: templateId },
      include: {
        exercises: true,
      },
    });

    if (!template) {
      throw new NotFoundException('Template not found');
    }

    if (!template.isTemplate) {
      throw new BadRequestException('The specified workout plan is not a template');
    }

    // Verify target user exists
    const targetUser = await this.prisma.user.findUnique({
      where: { id: createData.userId },
    });

    if (!targetUser) {
      throw new NotFoundException('Target user not found');
    }

    // Check permissions: users can only create plans for themselves unless they're admin/coach
    if (currentUserId && currentUserId !== createData.userId) {
      const currentUser = await this.prisma.user.findUnique({
        where: { id: currentUserId },
      });

      if (!currentUser || !currentUser.role || !['ADMIN', 'COACH'].includes(currentUser.role)) {
        throw new ForbiddenException('You can only create workout plans for yourself');
      }
    }

    // Create new workout plan from template
    const newWorkoutPlan = await this.prisma.workoutPlan.create({
      data: {
        userId: createData.userId,
        name: createData.name || `${template.name} (Copy)`,
        description: createData.description || template.description,
        picture: template.picture,
        planType: template.planType,
        status: template.status,
        days: template.days,
        isTemplate: false, // The copy is not a template
      },
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

    // Copy exercises from template
    if (template.exercises.length > 0) {
      const exerciseData = template.exercises.map(exercise => ({
        workoutPlanId: newWorkoutPlan.id,
        exerciseId: exercise.exerciseId,
        dayNumber: exercise.dayNumber,
        weight: exercise.weight,
      }));

      await this.prisma.workoutExercise.createMany({
        data: exerciseData,
      });
    }

    // Return the complete workout plan with exercises
    return this.findOne(newWorkoutPlan.id);
  }

  async toggleTemplateStatus(id: string, isTemplate: boolean, currentUserId: string): Promise<WorkoutPlan> {
    const workoutPlan = await this.findOne(id);

    // Check if user owns this workout plan or is admin
    if (workoutPlan.userId !== currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
      });
      if (!user || user.role !== 'ADMIN') {
        throw new ForbiddenException('You can only modify your own workout plans');
      }
    }

    // Only ADMIN and COACH can create templates
    if (isTemplate) {
      const currentUser = await this.prisma.user.findUnique({
        where: { id: currentUserId },
      });

      if (!currentUser || !currentUser.role || !['ADMIN', 'COACH'].includes(currentUser.role)) {
        throw new ForbiddenException('Only admins and coaches can create templates');
      }
    }

    return this.prisma.workoutPlan.update({
      where: { id },
      data: { isTemplate },
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
