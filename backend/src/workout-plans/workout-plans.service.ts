import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WorkoutPlan, WorkoutExercise } from '@prisma/client';
import { CreateWorkoutPlanDto } from './dto/create-workout-plan.dto';
import { UpdateWorkoutPlanDto } from './dto/update-workout-plan.dto';
import { CreateWorkoutExerciseDto } from './dto/create-workout-exercise.dto';
import { CreateWorkoutDayDto } from './dto/create-workout-day.dto';
import { UpdateWorkoutDayDto } from './dto/update-workout-day.dto';

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
        workoutDays: {
          include: {
            exercises: true,
          },
          orderBy: { dayNumber: 'asc' },
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

    // Copy exercises from template: create days and attach exercises to those days
    if (template.exercises.length > 0) {
      const uniqueDayNumbers = Array.from(
        new Set(template.exercises.map(e => e.dayNumber).filter((n): n is number => n !== null && n !== undefined))
      );

      const dayIdByNumber = new Map<number, string>();
      for (const n of uniqueDayNumbers) {
        const day = await this.prisma.workoutDay.create({
          data: { workoutPlanId: newWorkoutPlan.id, dayNumber: n },
        });
        dayIdByNumber.set(n, day.id);
      }

      // If there were exercises without a dayNumber, create a generic day once
      const hasNoDay = template.exercises.some(e => e.dayNumber === null || e.dayNumber === undefined);
      let genericDayId: string | undefined = undefined;
      if (hasNoDay) {
        const day = await this.prisma.workoutDay.create({
          data: { workoutPlanId: newWorkoutPlan.id, dayNumber: null },
        });
        genericDayId = day.id;
      }

      const exerciseCreates = template.exercises.map(exercise => {
        const n = exercise.dayNumber as number | null | undefined;
        return this.prisma.workoutExercise.create({
          data: {
            workoutPlanId: newWorkoutPlan.id,
            workoutDayId: n != null ? dayIdByNumber.get(n)! : genericDayId!,
            exerciseId: exercise.exerciseId,
            dayNumber: exercise.dayNumber ?? undefined,
            weight: exercise.weight ?? undefined,
          },
        });
      });

      await this.prisma.$transaction(exerciseCreates);
    }

    // Return the complete workout plan with exercises and days
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

  // Workout Day methods
  async createDay(dto: CreateWorkoutDayDto) {
    const plan = await this.prisma.workoutPlan.findUnique({ where: { id: dto.workoutPlanId } });
    if (!plan) throw new NotFoundException('Workout plan not found');

    return this.prisma.workoutDay.create({
      data: {
        workoutPlanId: dto.workoutPlanId,
        dayNumber: dto.dayNumber,
        date: dto.date ? new Date(dto.date) : undefined,
      },
    });
  }

  async listDays(workoutPlanId: string) {
    const plan = await this.prisma.workoutPlan.findUnique({ where: { id: workoutPlanId } });
    if (!plan) throw new NotFoundException('Workout plan not found');

    return this.prisma.workoutDay.findMany({
      where: { workoutPlanId },
      orderBy: { dayNumber: 'asc' },
      include: { exercises: true },
    });
  }

  async updateDay(dayId: string, dto: UpdateWorkoutDayDto) {
    const day = await this.prisma.workoutDay.findUnique({ where: { id: dayId } });
    if (!day) throw new NotFoundException('Workout day not found');

    return this.prisma.workoutDay.update({
      where: { id: dayId },
      data: {
        dayNumber: dto.dayNumber,
        date: dto.date ? new Date(dto.date) : undefined,
      },
    });
  }

  async removeDay(dayId: string) {
    const day = await this.prisma.workoutDay.findUnique({
      where: { id: dayId },
      include: { exercises: true },
    });
    if (!day) throw new NotFoundException('Workout day not found');
    if (day.exercises.length > 0) {
      throw new BadRequestException('Cannot delete a day that has exercises. Remove exercises first.');
    }
    return this.prisma.workoutDay.delete({ where: { id: dayId } });
  }

  // Workout Exercise methods
  async addExercise(createWorkoutExerciseDto: CreateWorkoutExerciseDto): Promise<WorkoutExercise> {
    const { workoutDayId, workoutPlanId, dayNumber, exerciseId, weight } = createWorkoutExerciseDto;

    let dayId = workoutDayId;
    let planId = workoutPlanId;

    if (!exerciseId) {
      throw new BadRequestException('exerciseId is required');
    }

    if (!dayId) {
      // Resolve or create day from planId + dayNumber
      if (!planId) {
        throw new BadRequestException('Provide workoutDayId or workoutPlanId');
      }
      const plan = await this.prisma.workoutPlan.findUnique({ where: { id: planId } });
      if (!plan) throw new NotFoundException('Workout plan not found');

      let day = await this.prisma.workoutDay.findFirst({ where: { workoutPlanId: planId, dayNumber: dayNumber ?? undefined } });
      if (!day) {
        day = await this.prisma.workoutDay.create({ data: { workoutPlanId: planId, dayNumber: dayNumber ?? undefined } });
      }
      dayId = day.id;
    } else {
      // Validate day and set planId from it if missing
      const day = await this.prisma.workoutDay.findUnique({ where: { id: dayId } });
      if (!day) throw new NotFoundException('Workout day not found');
      planId = planId ?? day.workoutPlanId;
    }

    return this.prisma.workoutExercise.create({
      data: {
        workoutPlanId: planId!,
        workoutDayId: dayId!,
        exerciseId,
        dayNumber: dayNumber,
        weight: weight,
      },
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

    // Map allowable fields
    const data: any = {};
    if (updateData.exerciseId !== undefined) data.exerciseId = updateData.exerciseId;
    if (updateData.weight !== undefined) data.weight = updateData.weight;
    if (updateData.dayNumber !== undefined) data.dayNumber = updateData.dayNumber;
    if (updateData.workoutDayId) data.workoutDayId = updateData.workoutDayId;

    return this.prisma.workoutExercise.update({
      where: { id: workoutExerciseId },
      data,
      include: {
        workoutPlan: true,
      },
    });
  }
}
