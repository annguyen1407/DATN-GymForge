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
});
