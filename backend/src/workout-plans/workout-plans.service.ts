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
        const copyTargetWeight = (exercise as any).targetWeight ?? undefined;
        return this.prisma.workoutExercise.create({
          data: {
            workoutPlanId: newWorkoutPlan.id,
            workoutDayId: n != null ? dayIdByNumber.get(n)! : genericDayId!,
            exerciseId: exercise.exerciseId,
            dayNumber: exercise.dayNumber ?? undefined,
            // planned fields copied if present
            targetSets: (exercise as any).targetSets ?? undefined,
            targetReps: (exercise as any).targetReps ?? undefined,
            targetWeight: copyTargetWeight,
            restTimeSec: (exercise as any).restTimeSec ?? undefined,
            timePerSetSec: (exercise as any).timePerSetSec ?? undefined,
            order: (exercise as any).order ?? undefined,
            notes: (exercise as any).notes ?? undefined,
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
    const {
      workoutDayId,
      workoutPlanId,
      dayNumber,
      exerciseId,
      targetSets,
      targetReps,
      targetWeight,
      restTimeSec,
      timePerSetSec,
      order,
      notes,
    } = createWorkoutExerciseDto;

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

    // Load exercise defaults for planned values
    const exercise = await this.prisma.exercise.findUnique({ where: { id: exerciseId } });
    if (!exercise) throw new NotFoundException('Exercise not found');

    const finalTargetSets = targetSets ?? exercise.defaultSets ?? undefined;
    const finalTargetReps = targetReps ?? exercise.defaultReps ?? undefined;
    const finalTargetWeight = (targetWeight ?? exercise.defaultWeight) ?? undefined;
    const finalRestTimeSec = restTimeSec ?? exercise.restTime ?? undefined;
    const finalTimePerSetSec = timePerSetSec ?? exercise.defaultTimePerSetSec ?? undefined;

    return this.prisma.workoutExercise.create({
      data: {
        workoutPlanId: planId!,
        workoutDayId: dayId!,
        exerciseId,
        dayNumber: dayNumber,
        // planned values
        targetSets: finalTargetSets,
        targetReps: finalTargetReps,
        targetWeight: finalTargetWeight,
        restTimeSec: finalRestTimeSec,
        timePerSetSec: finalTimePerSetSec,
        order: order ?? undefined,
        notes: notes ?? undefined,
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
    if (updateData.dayNumber !== undefined) data.dayNumber = updateData.dayNumber;
    if (updateData.workoutDayId) data.workoutDayId = updateData.workoutDayId;

    // Planned/target fields
    if (updateData.targetSets !== undefined) data.targetSets = updateData.targetSets;
    if (updateData.targetReps !== undefined) data.targetReps = updateData.targetReps;
    if (updateData.targetWeight !== undefined) {
      data.targetWeight = updateData.targetWeight;
    }
    if (updateData.restTimeSec !== undefined) data.restTimeSec = updateData.restTimeSec;
    if (updateData.timePerSetSec !== undefined) data.timePerSetSec = updateData.timePerSetSec;
    if (updateData.order !== undefined) data.order = updateData.order;
    if (updateData.notes !== undefined) data.notes = updateData.notes;

    return this.prisma.workoutExercise.update({
      where: { id: workoutExerciseId },
      data,
      include: {
        workoutPlan: true,
      },
    });
  }

  async getWorkoutExercises(filter: {
    workoutPlanId?: string;
    workoutDayId?: string;
    dayNumber?: number;
    exerciseId?: string;
  }) {
    const { workoutPlanId, workoutDayId, dayNumber, exerciseId } = filter;

    const where: any = {};
    if (workoutPlanId) where.workoutPlanId = workoutPlanId;
    if (workoutDayId) where.workoutDayId = workoutDayId;
    if (dayNumber !== undefined) where.dayNumber = dayNumber;
    if (exerciseId) where.exerciseId = exerciseId;

    return this.prisma.workoutExercise.findMany({
      where,
      orderBy: [
        { workoutDayId: 'asc' },
        { dayNumber: 'asc' },
        { order: 'asc' },
      ],
      include: {
        workoutPlan: true,
        workoutDay: true,
      },
    });
  }

  async getDayStats(dayId: string) {
    const day = await this.prisma.workoutDay.findUnique({
      where: { id: dayId },
      include: {
        workoutPlan: {
          select: { id: true, name: true, userId: true },
        },
      },
    });
    if (!day) throw new NotFoundException('Workout day not found');

    const exercises = await this.prisma.workoutExercise.findMany({
      where: { workoutDayId: dayId },
      select: {
        id: true,
        exerciseId: true,
        targetSets: true,
        targetReps: true,
        targetWeight: true,
        restTimeSec: true,
        timePerSetSec: true,
      },
    });

    const ids = exercises.map((e) => e.id);

    const agg = ids.length
      ? await this.prisma.workoutExerciseLog.groupBy({
          by: ['workoutExerciseId'],
          where: { workoutExerciseId: { in: ids } },
          _count: { _all: true },
          _avg: { progressPercent: true },
          _sum: { caloriesBurned: true },
        })
      : [];

    const aggMap = new Map(agg.map((a) => [a.workoutExerciseId, a]));

    const stats = exercises.map((e) => {
      const a = aggMap.get(e.id) as any;
      return {
        workoutExerciseId: e.id,
        exerciseId: e.exerciseId,
        planned: {
          targetSets: e.targetSets,
          targetReps: e.targetReps,
          targetWeight: e.targetWeight,
          restTimeSec: e.restTimeSec,
          timePerSetSec: e.timePerSetSec,
        },
        logsCount: a?._count?._all ?? 0,
        avgProgressPercent: a?._avg?.progressPercent ?? null,
        totalCaloriesBurned: a?._sum?.caloriesBurned ?? 0,
      };
    });

    return {
      workoutPlan: day.workoutPlan
        ? { id: day.workoutPlan.id, name: day.workoutPlan.name, userId: day.workoutPlan.userId }
        : null,
      day: {
        id: day.id,
        workoutPlanId: day.workoutPlanId,
        dayNumber: day.dayNumber,
        date: (day as any).date ?? null,
      },
      stats,
    };
  }

  async listExerciseLogs(workoutExerciseId: string) {
    const exists = await this.prisma.workoutExercise.findUnique({ where: { id: workoutExerciseId } });
    if (!exists) throw new NotFoundException('Workout exercise not found');

    return this.prisma.workoutExerciseLog.findMany({
      where: { workoutExerciseId },
      orderBy: { date: 'desc' },
    });
  }

}
