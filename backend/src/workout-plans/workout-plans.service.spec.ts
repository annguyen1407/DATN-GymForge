import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { WorkoutPlansService } from './workout-plans.service';
import { PrismaService } from '../prisma/prisma.service';
import { PlanType, PlanStatus } from '@prisma/client';

describe('WorkoutPlansService', () => {
  let service: WorkoutPlansService;
  let prismaService: PrismaService;

  const mockUser = {
    id: 'user-id',
    name: 'Test User',
    email: 'test@example.com',
    role: 'GYMER',
  };

  const mockWorkoutPlan = {
    id: 'workout-plan-id',
    userId: 'user-id',
    name: 'Full Body Workout',
    description: 'A comprehensive workout plan',
    planType: PlanType.STRENGTH,
    status: PlanStatus.ACTIVE,
    days: 30,
    picture: null,
    user: mockUser,
    exercises: [],
  };

  const mockWorkoutExercise = {
    id: 'workout-exercise-id',
    workoutPlanId: 'workout-plan-id',
    exerciseId: 'exercise-id',
    dayNumber: 1,
    weight: 50.0,
    workoutPlan: mockWorkoutPlan,
  };

  const mockPrismaService: any = {
    user: {
      findUnique: jest.fn(),
    },
    userSubscription: {
      findFirst: jest.fn(),
    },
    workoutPlan: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    workoutExercise: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      findMany: jest.fn(),
      updateMany: jest.fn(),
    },
    workoutDay: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      count: jest.fn(),
      delete: jest.fn(),
      updateMany: jest.fn(),
      findMany: jest.fn(),
    },
    exercise: {
      findUnique: jest.fn(),
    },
    workoutExerciseLog: {
      groupBy: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WorkoutPlansService,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
      ],
    }).compile();

    service = module.get<WorkoutPlansService>(WorkoutPlansService);
    prismaService = module.get<PrismaService>(PrismaService);
  });

    // Mock interactive transaction to use same client for tx
    (mockPrismaService as any).$transaction.mockImplementation(async (cb: any) => cb(mockPrismaService));


  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    const createWorkoutPlanDto = {
      userId: 'user-id',
      name: 'Full Body Workout',
      description: 'A comprehensive workout plan',
      planType: PlanType.STRENGTH,
      status: PlanStatus.ACTIVE,
      days: 30,
    };

    it('should create a workout plan successfully', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      mockPrismaService.workoutPlan.create.mockResolvedValue(mockWorkoutPlan);

      const result = await service.create(createWorkoutPlanDto);

      expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
        where: { id: createWorkoutPlanDto.userId },
      });
      expect(mockPrismaService.workoutPlan.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: createWorkoutPlanDto.userId,
          name: createWorkoutPlanDto.name,
          description: createWorkoutPlanDto.description,
          planType: createWorkoutPlanDto.planType,
          status: createWorkoutPlanDto.status,
          days: createWorkoutPlanDto.days,
          isTemplate: false,
          isPremiumOnly: false,
        }),
        include: expect.any(Object),
      });
      expect(result).toEqual(mockWorkoutPlan);
    });

    it('should throw NotFoundException if user does not exist', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(service.create(createWorkoutPlanDto)).rejects.toThrow(NotFoundException);
    });
  });

  describe('findAll', () => {
    it('should return all workout plans', async () => {
      const workoutPlans = [mockWorkoutPlan];
      mockPrismaService.workoutPlan.findMany.mockResolvedValue(workoutPlans);

      const result = await service.findAll();

      expect(mockPrismaService.workoutPlan.findMany).toHaveBeenCalledWith({
        where: { isTemplate: false },
        include: expect.any(Object),
        orderBy: { name: 'asc' },
      });
      expect(result).toEqual(workoutPlans);
    });

    it('should filter by userId when provided', async () => {
      const workoutPlans = [mockWorkoutPlan];
      mockPrismaService.workoutPlan.findMany.mockResolvedValue(workoutPlans);

      const result = await service.findAll('user-id');

      expect(mockPrismaService.workoutPlan.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-id', isTemplate: false },
        include: expect.any(Object),
        orderBy: { name: 'asc' },
      });
      expect(result).toEqual(workoutPlans);
    });
  });

  describe('findOne', () => {
    it('should return a workout plan by id', async () => {
      mockPrismaService.workoutPlan.findUnique.mockResolvedValue(mockWorkoutPlan);

      const result = await service.findOne('workout-plan-id');

      expect(mockPrismaService.workoutPlan.findUnique).toHaveBeenCalledWith({
        where: { id: 'workout-plan-id' },
        include: expect.any(Object),
      });
      expect(result).toEqual(mockWorkoutPlan);
    });

    it('should throw NotFoundException if workout plan not found', async () => {
      mockPrismaService.workoutPlan.findUnique.mockResolvedValue(null);
      await expect(service.findOne('invalid-id')).rejects.toThrow(NotFoundException);
    });
  });

  describe('findTemplates (premiumOnly filter)', () => {
    it('applies premiumOnly=true', async () => {
      await service.findTemplates(undefined, 'true');
      expect((prismaService as any).workoutPlan.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: expect.objectContaining({ isTemplate: true, isPremiumOnly: true }) }),
      );
    });

    it('applies premiumOnly=false', async () => {
      await service.findTemplates(undefined, 'false');
      expect((prismaService as any).workoutPlan.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: expect.objectContaining({ isTemplate: true, isPremiumOnly: false }) }),
      );
    });
  });

  describe('findOne strict premium gating for template', () => {
    it('throws Forbidden for non-premium gymer viewing premium-only template', async () => {
      // First call from assertPlanVisibleToUser
      (prismaService as any).workoutPlan.findUnique.mockResolvedValueOnce({ id: 'tpl1', isTemplate: true, isPremiumOnly: true, userId: 'owner' });
      // Second call for findOne payload
      (prismaService as any).workoutPlan.findUnique.mockResolvedValueOnce({ id: 'tpl1', isTemplate: true, isPremiumOnly: true, userId: 'owner', exercises: [], workoutDays: [] });
      // User checks in assert and premium check
      (prismaService as any).user.findUnique
        .mockResolvedValueOnce({ id: 'viewer', role: 'GYMER' }) // assertPlanVisibleToUser
        .mockResolvedValueOnce({ id: 'viewer', role: 'GYMER', premiumExpiresAt: null }); // isUserPremium
      (prismaService as any).userSubscription.findFirst.mockResolvedValueOnce(null);

      await expect(service.findOne('tpl1', 'viewer')).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('allows ADMIN to view premium-only template', async () => {
      (prismaService as any).workoutPlan.findUnique.mockResolvedValueOnce({ id: 'tpl1', isTemplate: true, isPremiumOnly: true, userId: 'owner' });
      (prismaService as any).workoutPlan.findUnique.mockResolvedValueOnce({ id: 'tpl1', isTemplate: true, isPremiumOnly: true, userId: 'owner', exercises: [], workoutDays: [] });
      // First for assertPlanVisibleToUser, second for strict gating check
      (prismaService as any).user.findUnique
        .mockResolvedValueOnce({ id: 'admin', role: 'ADMIN' })
        .mockResolvedValueOnce({ id: 'admin', role: 'ADMIN' });

      const res = await service.findOne('tpl1', 'admin');
      expect(res.id).toBe('tpl1');
    });
  });

  describe('update', () => {
    const updateWorkoutPlanDto = {
      name: 'Updated Workout Plan',
      description: 'Updated description',
    };

    it('should update a workout plan successfully', async () => {
      mockPrismaService.workoutPlan.findUnique.mockResolvedValue(mockWorkoutPlan);
      const updatedWorkoutPlan = { ...mockWorkoutPlan, ...updateWorkoutPlanDto };
      mockPrismaService.workoutPlan.update.mockResolvedValue(updatedWorkoutPlan);

      const result = await service.update('workout-plan-id', updateWorkoutPlanDto, 'user-id');

      expect(mockPrismaService.workoutPlan.update).toHaveBeenCalledWith({
        where: { id: 'workout-plan-id' },
        data: updateWorkoutPlanDto,
        include: expect.any(Object),
      });
      expect(result).toEqual(updatedWorkoutPlan);
    });

    it('should throw ForbiddenException if user does not own the workout plan', async () => {
      const otherUserWorkoutPlan = { ...mockWorkoutPlan, userId: 'other-user-id' };
      mockPrismaService.workoutPlan.findUnique.mockResolvedValue(otherUserWorkoutPlan);
      mockPrismaService.user.findUnique.mockResolvedValue({ ...mockUser, role: 'GYMER' });

      await expect(
        service.update('workout-plan-id', updateWorkoutPlanDto, 'user-id')
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow admin to update any workout plan', async () => {
      const otherUserWorkoutPlan = { ...mockWorkoutPlan, userId: 'other-user-id' };
      mockPrismaService.workoutPlan.findUnique.mockResolvedValue(otherUserWorkoutPlan);


      mockPrismaService.user.findUnique.mockResolvedValue({ ...mockUser, role: 'ADMIN' });
      const updatedWorkoutPlan = { ...otherUserWorkoutPlan, ...updateWorkoutPlanDto };
      mockPrismaService.workoutPlan.update.mockResolvedValue(updatedWorkoutPlan);

      const result = await service.update('workout-plan-id', updateWorkoutPlanDto, 'user-id');

      expect(result).toEqual(updatedWorkoutPlan);
    });
  });

  describe('addExercise', () => {
    const createWorkoutExerciseDto = {
      workoutPlanId: 'workout-plan-id',
      exerciseId: 'exercise-id',
      dayNumber: 1,
      weight: 50.0,
    };

    it('should add exercise to workout plan successfully', async () => {
      mockPrismaService.workoutPlan.findUnique.mockResolvedValue(mockWorkoutPlan);
      mockPrismaService.workoutDay.findFirst.mockResolvedValue(null);
      mockPrismaService.workoutDay.create.mockResolvedValue({ id: 'day-id', workoutPlanId: 'workout-plan-id', dayNumber: 1 });
      mockPrismaService.workoutDay.count.mockResolvedValue(1);
      (mockPrismaService as any).exercise.findUnique.mockResolvedValue({ id: 'exercise-id' });
      mockPrismaService.workoutExercise.create.mockResolvedValue(mockWorkoutExercise);

      const result = await service.addExercise(createWorkoutExerciseDto);

      expect(mockPrismaService.workoutPlan.findUnique).toHaveBeenCalledWith({
        where: { id: createWorkoutExerciseDto.workoutPlanId },
      });
      expect(mockPrismaService.workoutDay.create).toHaveBeenCalled();
      expect((mockPrismaService as any).exercise.findUnique).toHaveBeenCalledWith({ where: { id: createWorkoutExerciseDto.exerciseId } });
      expect(mockPrismaService.workoutExercise.create).toHaveBeenCalled();
      expect(result).toEqual(mockWorkoutExercise);
    });

    it('should throw NotFoundException if workout plan does not exist', async () => {
      mockPrismaService.workoutPlan.findUnique.mockResolvedValue(null);

      await expect(service.addExercise(createWorkoutExerciseDto)).rejects.toThrow(NotFoundException);
    });
  });

  describe('removeExercise', () => {
    it('should remove exercise from workout plan successfully', async () => {
      mockPrismaService.workoutExercise.findUnique.mockResolvedValue(mockWorkoutExercise);
      mockPrismaService.workoutExercise.delete.mockResolvedValue(mockWorkoutExercise);

      const result = await service.removeExercise('workout-exercise-id');

      expect(mockPrismaService.workoutExercise.findUnique).toHaveBeenCalledWith({
        where: { id: 'workout-exercise-id' },
      });


      expect(mockPrismaService.workoutExercise.delete).toHaveBeenCalledWith({
        where: { id: 'workout-exercise-id' },
      });
      expect(result).toEqual(mockWorkoutExercise);
    });

    it('should throw NotFoundException if workout exercise does not exist', async () => {
      mockPrismaService.workoutExercise.findUnique.mockResolvedValue(null);

      await expect(service.removeExercise('invalid-id')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getDayStats', () => {
    it('should return parent plan, day metadata, and aggregated stats', async () => {
      const dayId = 'day-id';
      (mockPrismaService as any).workoutDay.findUnique.mockResolvedValue({
        id: dayId,
        workoutPlanId: 'workout-plan-id',
        dayNumber: 1,
        date: new Date('2025-01-20'),
        workoutPlan: { id: 'workout-plan-id', name: 'Full Body Workout', userId: 'user-id' },
      });
      (mockPrismaService as any).workoutPlan.findUnique.mockResolvedValue({ id: 'workout-plan-id', userId: 'user-id' });
      (mockPrismaService as any).workoutExercise.findMany.mockResolvedValue([
        { id: 'we-1', exerciseId: 'ex-1', targetSets: 3, targetReps: 10, targetWeight: 50, restTimeSec: 60, timePerSetSec: 40 },
      ]);
      (mockPrismaService as any).workoutExerciseLog.groupBy.mockResolvedValue([
        { workoutExerciseId: 'we-1', _count: { _all: 2 }, _avg: { progressPercent: 60 }, _sum: { caloriesBurned: 200 } },
      ]);

      const res = await service.getDayStats(dayId);
      expect(res.workoutPlan).toEqual({ id: 'workout-plan-id', name: 'Full Body Workout', userId: 'user-id' });
      expect(res.day.id).toBe(dayId);
      expect(res.stats).toHaveLength(1);
      expect(res.stats[0].workoutExerciseId).toBe('we-1');
      expect(res.stats[0].logsCount).toBe(2);
      expect(res.stats[0].totalCaloriesBurned).toBe(200);
    });

    it('should handle a day that has no exercises', async () => {
      const dayId = 'day-empty';
      (mockPrismaService as any).workoutDay.findUnique.mockResolvedValue({
        id: dayId,
        workoutPlanId: 'workout-plan-id',
        dayNumber: 2,
        date: null,
        workoutPlan: { id: 'workout-plan-id', name: 'Full Body Workout', userId: 'user-id' },
      });
      (mockPrismaService as any).workoutPlan.findUnique.mockResolvedValue({ id: 'workout-plan-id', userId: 'user-id' });
      (mockPrismaService as any).workoutExercise.findMany.mockResolvedValue([]);

      const res = await service.getDayStats(dayId);
      expect(res.workoutPlan).toEqual({ id: 'workout-plan-id', name: 'Full Body Workout', userId: 'user-id' });
      expect(res.day.id).toBe(dayId);
      expect(res.stats).toEqual([]);
    });
  });

  describe('createDay', () => {
    it('should create day and update plan days count', async () => {
      (mockPrismaService as any).workoutPlan.findUnique.mockResolvedValue(mockWorkoutPlan);
      const createdDay = { id: 'day-id', workoutPlanId: 'workout-plan-id', dayNumber: 3, date: null };
      (mockPrismaService as any).workoutDay.create.mockResolvedValue(createdDay);
      (mockPrismaService as any).workoutDay.count.mockResolvedValue(3);

      const res = await service.createDay({ workoutPlanId: 'workout-plan-id', dayNumber: 3 } as any);

      expect((mockPrismaService as any).workoutDay.create).toHaveBeenCalled();
      expect((mockPrismaService as any).workoutPlan.update).toHaveBeenCalledWith({
        where: { id: 'workout-plan-id' },
        data: { days: 3 },
      });
      expect(res).toEqual(createdDay);
    });
  });

  describe('removeDay', () => {
    it('should delete day, renumber subsequent days, and update days count', async () => {
      (mockPrismaService as any).$transaction.mockImplementation(async (cb: any) => cb(mockPrismaService));
      (mockPrismaService as any).workoutDay.findUnique.mockResolvedValue({ id: 'day-2', workoutPlanId: 'workout-plan-id', dayNumber: 2, exercises: [] });
      (mockPrismaService as any).workoutDay.delete.mockResolvedValue({ id: 'day-2' });
      (mockPrismaService as any).workoutDay.updateMany.mockResolvedValue({ count: 1 });
      (mockPrismaService as any).workoutExercise.updateMany.mockResolvedValue({ count: 2 });
      (mockPrismaService as any).workoutDay.count.mockResolvedValue(1);

      const res = await service.removeDay('day-2');

      expect((mockPrismaService as any).workoutDay.delete).toHaveBeenCalledWith({ where: { id: 'day-2' } });
      expect((mockPrismaService as any).workoutDay.updateMany).toHaveBeenCalledWith({
        where: { workoutPlanId: 'workout-plan-id', dayNumber: { gt: 2 } },
        data: { dayNumber: { decrement: 1 } },
      });
      expect((mockPrismaService as any).workoutExercise.updateMany).toHaveBeenCalledWith({
        where: { workoutDay: { workoutPlanId: 'workout-plan-id' }, dayNumber: { gt: 2 } },
        data: { dayNumber: { decrement: 1 } },
      });
      expect((mockPrismaService as any).workoutPlan.update).toHaveBeenCalledWith({
        where: { id: 'workout-plan-id' },
        data: { days: 1 },
      });
      expect(res).toEqual({ id: 'day-2' });
    });
  });

});


