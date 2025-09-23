import { Test, TestingModule } from '@nestjs/testing';
import { ExerciseLogsService } from './exercise-logs.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException } from '@nestjs/common';

describe('ExerciseLogsService', () => {
  let service: ExerciseLogsService;
  let prismaService: PrismaService;

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
    },
    exercise: {
      findUnique: jest.fn(),
    },
    workoutPlan: {
      findUnique: jest.fn(),
    },
    log: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    exerciseLog: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      delete: jest.fn(),
    },
    workoutExercise: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
    },
    workoutDay: {
      update: jest.fn(),
    },
    setsLog: {
      createMany: jest.fn(),
      deleteMany: jest.fn(),
      findMany: jest.fn(),
    },
    workoutExerciseLog: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ExerciseLogsService,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
      ],
    }).compile();

    service = module.get<ExerciseLogsService>(ExerciseLogsService);
    prismaService = module.get<PrismaService>(PrismaService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createExerciseLog', () => {
    it('should throw NotFoundException when user does not exist', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      const createDto = {
        userId: 'non-existent-user',
        workoutExerciseId: 'we-id',
        date: '2024-01-15',
        sets: [],
      };

      await expect(service.createExerciseLog(createDto)).rejects.toThrow(NotFoundException);
      expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'non-existent-user' },
      });
    });

    it('should create exercise log successfully', async () => {
      const mockUser = { id: 'user-id', name: 'Test User' };
      const mockExercise = { id: 'exercise-id', name: 'Push-ups', met: 3.5 };
      const mockWorkoutExercise = { id: 'we-id' };
      const mockLog = { id: 'log-id', userId: 'user-id', dateLogged: new Date('2024-01-15') };
      const mockExerciseLog = { id: 'exercise-log-id', workoutLogId: 'log-id' };

      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      mockPrismaService.workoutExercise.findUnique.mockResolvedValue(mockWorkoutExercise);
      mockPrismaService.log.findFirst.mockResolvedValue(null);
      mockPrismaService.log.create.mockResolvedValue(mockLog);
      mockPrismaService.exerciseLog.create.mockResolvedValue(mockExerciseLog);
      mockPrismaService.exerciseLog.findUnique.mockResolvedValue({
        ...mockExerciseLog,
        setsLog: [],
      });
      mockPrismaService.workoutExercise.findMany.mockResolvedValue([]);
      mockPrismaService.workoutExerciseLog.findMany.mockResolvedValue([]);

      const createDto = {
        userId: 'user-id',
        workoutExerciseId: 'we-id',
        date: '2024-01-15',
        totalCaloriesBurned: 100,
        sets: [
          { setNumber: 1, reps: 12, weight: 50 },
        ],
      };

      const result = await service.createExerciseLog(createDto);

      expect(result).toBeDefined();
      expect(mockPrismaService.log.create).toHaveBeenCalled();
      expect(mockPrismaService.exerciseLog.create).toHaveBeenCalled();
    });
  });

  describe('getDailyStats', () => {
    it('should return empty stats when no logs exist', async () => {
      mockPrismaService.log.findMany.mockResolvedValue([]);

      const result = await service.getDailyStats('user-id', '2024-01-15');

      expect(result).toEqual({
        date: '2024-01-15',
        totalExercises: 0,
        totalSets: 0,
        totalReps: 0,
        totalCaloriesBurned: 0,
        totalCaloriesIntake: 0,
        totalWorkoutTime: 0,
        averageWeight: 0,
        workoutPlansCompleted: [],
      });
    });
  });

  describe('quickLogExercise', () => {
    it('should throw NotFoundException when workout exercise does not exist', async () => {
      mockPrismaService.workoutExercise.findUnique.mockResolvedValue(null);

      const quickLogDto = {
        workoutExerciseId: 'non-existent-we',
        sets: [{ reps: 12, weight: 50 }],
      };

      await expect(service.quickLogExercise('user-id', quickLogDto as any)).rejects.toThrow(NotFoundException);
    });
  });

  describe('time tracking', () => {
    it('createExerciseLog sets totalTime and updates day totalWorkoutTime', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({ id: 'u1' });
      mockPrismaService.workoutExercise.findUnique.mockResolvedValue({ id: 'we1' });
      mockPrismaService.log.findFirst.mockResolvedValue({ id: 'log-1', totalWorkoutTime: 120, caloriesBurned: 0 });
      mockPrismaService.exerciseLog.create.mockResolvedValue({ id: 'elog-1', workoutLogId: 'log-1' });
      mockPrismaService.exerciseLog.findUnique.mockResolvedValue({ id: 'elog-1', setsLog: [] });

      await service.createExerciseLog({
        userId: 'u1', workoutExerciseId: 'we1', date: '2025-01-10',
        sets: [ { times: 60 }, { times: 30 } ],
      } as any);

      expect(mockPrismaService.workoutExerciseLog.create).toHaveBeenCalledWith(expect.objectContaining({
        data: expect.objectContaining({ totalTime: 90 })
      }));
      expect(mockPrismaService.log.update).toHaveBeenCalledWith({ where: { id: 'log-1' }, data: { totalWorkoutTime: 210 } });
    });

    it('updateExerciseLog recalculates totalWorkoutTime from all sets', async () => {
      // First fetch exists
      mockPrismaService.exerciseLog.findUnique
        .mockResolvedValueOnce({ id: 'elog-1', setsLog: [] }) // from findExerciseLogById
        .mockResolvedValueOnce({ workoutLogId: 'log-1' });     // for parent lookup

      mockPrismaService.setsLog.deleteMany.mockResolvedValue({} as any);
      mockPrismaService.setsLog.createMany.mockResolvedValue({} as any);

      mockPrismaService.exerciseLog.findMany.mockResolvedValue([
        { setsLog: [{ times: 30 }, { times: 60 }] },
        { setsLog: [{ times: 120 }] },
      ] as any);

      await service.updateExerciseLog('elog-1', { sets: [{ times: 10 }] } as any);

      expect(mockPrismaService.log.update).toHaveBeenCalledWith({ where: { id: 'log-1' }, data: { totalWorkoutTime: 210 } });
    });

    it('getWeeklyStats returns totalWorkoutTime (minutes) sum of days', async () => {
      const values = [30, 0, 45, 15, 0, 60, 0];
      let call = 0;
      const dailySpy = jest.spyOn(service, 'getDailyStats').mockImplementation(async () => ({
        date: 'x', totalExercises: 1, totalSets: 0, totalReps: 0, totalCaloriesBurned: 0, totalCaloriesIntake: 0,
        totalWorkoutTime: values[call++] ?? 0, averageWeight: 0, workoutPlansCompleted: []
      }));

      const res = await service.getWeeklyStats('u1', '2025-01-06');
      expect(res.totalWorkoutTime).toBe(values.reduce((a, b) => a + b, 0));
      expect((res as any).averageDailyWorkoutTime).toBeUndefined();
      dailySpy.mockRestore();
    });

    it('getMonthlyStats returns totalWorkoutTime (minutes) from logs', async () => {
      mockPrismaService.log.findMany.mockResolvedValue([
        { id: 'l1', totalWorkoutTime: 3600, caloriesBurned: 0, workoutExerciseLogs: [] },
        { id: 'l2', totalWorkoutTime: 1800, caloriesBurned: 0, workoutExerciseLogs: [] },
      ] as any);
      mockPrismaService.exerciseLog.findMany.mockResolvedValue([] as any);
      jest.spyOn(service, 'getWeeklyStats').mockResolvedValue({
        weekStart: '2025-01-01', weekEnd: '2025-01-07', totalWorkoutDays: 0, totalExercises: 0, totalCaloriesBurned: 0,
        totalWorkoutTime: 0, dailyStats: []
      } as any);

      const res = await service.getMonthlyStats('u1', '2025-01');
      expect(res.totalWorkoutTime).toBe(Math.round((3600 + 1800) / 60));
    });
  });

});

