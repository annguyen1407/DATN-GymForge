import { Test, TestingModule } from '@nestjs/testing';
import { MealsService } from './meals.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { MealType } from '@prisma/client';

describe('MealsService', () => {
  let service: MealsService;
  // We will use mockPrisma directly for setting expectations

  const mockPrisma = {
    user: { findUnique: jest.fn() },
    log: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    meal: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
      update: jest.fn(),
      aggregate: jest.fn(),
      groupBy: jest.fn(),
    },
    $transaction: jest.fn(),
  } as any;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MealsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get(MealsService);
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('addMealForDay', () => {
    it('throws NotFound if user missing', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      await expect(
        service.addMealForDay('user-1', '2025-01-10', { name: 'Chicken', calories: 300 }) as any,
      ).rejects.toThrow(NotFoundException);
    });

    it('creates log if absent and creates meal, updates totals', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1', weight: 70, height: 175 } as any);
      mockPrisma.log.findFirst.mockResolvedValue(null);
      mockPrisma.log.create.mockResolvedValue({ id: 'log-1', userId: 'user-1', dateLogged: new Date('2025-01-10'), caloriesIntake: 300 } as any);
      mockPrisma.meal.create.mockResolvedValue({ id: 'meal-1', name: 'Chicken', calories: 300, type: null } as any);

      const res = await service.addMealForDay('user-1', '2025-01-10', { name: 'Chicken', calories: 300 });

      expect(mockPrisma.log.create).toHaveBeenCalled();
      expect(mockPrisma.meal.create).toHaveBeenCalled();
      expect(res).toEqual(expect.objectContaining({ id: 'meal-1' }));
    });

    it('updates existing log totals and creates meal', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-1', weight: 70, height: 175 } as any);
      mockPrisma.log.findFirst.mockResolvedValue({ id: 'log-1', userId: 'user-1', caloriesIntake: 200 } as any);
      mockPrisma.log.update.mockResolvedValue({} as any);
      mockPrisma.meal.create.mockResolvedValue({ id: 'meal-1', name: 'Rice', calories: 250 } as any);

      const res = await service.addMealForDay('user-1', '2025-01-10', { name: 'Rice', calories: 250 });
      expect(mockPrisma.log.update).toHaveBeenCalledWith({ where: { id: 'log-1' }, data: expect.objectContaining({ caloriesIntake: 450 }) });
      expect(res).toEqual(expect.objectContaining({ id: 'meal-1' }));
    });
  });

  describe('listMealsForDay', () => {
    it('returns [] when no log', async () => {
      mockPrisma.log.findFirst.mockResolvedValue(null);
      const res = await service.listMealsForDay('user-1', '2025-01-10');
      expect(res).toEqual([]);
    });

    it('returns mapped meals for the day', async () => {
      mockPrisma.log.findFirst.mockResolvedValue({ id: 'log-1' } as any);
      mockPrisma.meal.findMany.mockResolvedValue([
        { id: 'm1', name: 'Eggs', calories: 200, type: MealType.BREAKFAST },
        { id: 'm2', name: 'Chicken', calories: 350, type: MealType.LUNCH },
      ] as any);
      const res = await service.listMealsForDay('user-1', '2025-01-10');
      expect(res).toEqual([
        { mealId: 'm1', name: 'Eggs', calories: 200, type: MealType.BREAKFAST },
        { mealId: 'm2', name: 'Chicken', calories: 350, type: MealType.LUNCH },
      ]);
    });
  });

  describe('updateMeal', () => {
    it('validates existence and ownership/date', async () => {
      mockPrisma.meal.findUnique.mockResolvedValue(null);
      await expect(service.updateMeal('user-1', '2025-01-10', 'mid', {})).rejects.toThrow(NotFoundException);

      mockPrisma.meal.findUnique.mockResolvedValue({ id: 'mid', logId: 'lid' } as any);
      mockPrisma.log.findUnique.mockResolvedValue(null);
      await expect(service.updateMeal('user-1', '2025-01-10', 'mid', {})).rejects.toThrow(NotFoundException);

      mockPrisma.log.findUnique.mockResolvedValue({ id: 'lid', userId: 'user-2', dateLogged: new Date('2025-01-10') } as any);
      await expect(service.updateMeal('user-1', '2025-01-10', 'mid', {})).rejects.toThrow(NotFoundException);

      mockPrisma.log.findUnique.mockResolvedValue({ id: 'lid', userId: 'user-1', dateLogged: new Date('2025-01-11') } as any);
      await expect(service.updateMeal('user-1', '2025-01-10', 'mid', {})).rejects.toThrow(NotFoundException);
    });

    it('applies calorie delta and returns updated meal', async () => {
      mockPrisma.meal.findUnique.mockResolvedValue({ id: 'mid', logId: 'lid', calories: 300, name: 'Chicken', type: MealType.DINNER } as any);
      mockPrisma.log.findUnique.mockResolvedValue({ id: 'lid', userId: 'user-1', dateLogged: new Date('2025-01-10'), caloriesIntake: 1000 } as any);
      mockPrisma.meal.update.mockResolvedValue({ id: 'mid', name: 'Grilled Chicken', calories: 350, type: MealType.DINNER } as any);
      mockPrisma.log.update.mockResolvedValue({} as any);

      const res = await service.updateMeal('user-1', '2025-01-10', 'mid', { name: 'Grilled Chicken', calories: 350 });
      expect(mockPrisma.log.update).toHaveBeenCalledWith({ where: { id: 'lid' }, data: { caloriesIntake: 1050 } });
      expect(res).toEqual(expect.objectContaining({ id: 'mid', calories: 350 }));
    });
  });

  describe('deleteMeal', () => {
    it('validates existence and ownership/date', async () => {
      mockPrisma.meal.findUnique.mockResolvedValue(null);
      await expect(service.deleteMeal('user-1', '2025-01-10', 'mid')).rejects.toThrow(NotFoundException);
      mockPrisma.meal.findUnique.mockResolvedValue({ id: 'mid', logId: null } as any);
      await expect(service.deleteMeal('user-1', '2025-01-10', 'mid')).rejects.toThrow(NotFoundException);

      mockPrisma.meal.findUnique.mockResolvedValue({ id: 'mid', logId: 'lid', calories: 300 } as any);
      mockPrisma.log.findUnique.mockResolvedValue({ id: 'lid', userId: 'user-2', dateLogged: new Date('2025-01-10'), caloriesIntake: 1000 } as any);
      await expect(service.deleteMeal('user-1', '2025-01-10', 'mid')).rejects.toThrow(NotFoundException);

      mockPrisma.log.findUnique.mockResolvedValue({ id: 'lid', userId: 'user-1', dateLogged: new Date('2025-01-11'), caloriesIntake: 1000 } as any);
      await expect(service.deleteMeal('user-1', '2025-01-10', 'mid')).rejects.toThrow(NotFoundException);
    });

    it('subtracts calories and deletes meal', async () => {
      mockPrisma.meal.findUnique.mockResolvedValue({ id: 'mid', logId: 'lid', calories: 300 } as any);
      mockPrisma.log.findUnique.mockResolvedValue({ id: 'lid', userId: 'user-1', dateLogged: new Date('2025-01-10'), caloriesIntake: 1000 } as any);
      mockPrisma.$transaction.mockImplementation(async (_fn: any) => {
        // Simulate transaction callback usage: our service uses array form, so directly update calls occurred already
        return [{} as any, {} as any];
      });

      const res = await service.deleteMeal('user-1', '2025-01-10', 'mid');
      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockPrisma.log.update).toHaveBeenCalledWith({ where: { id: 'lid' }, data: { caloriesIntake: 700 } });
      expect(res).toEqual({ ok: true });
    });
  });

  describe('getDailyIntake', () => {
    it('sums calories over logs for date', async () => {
      mockPrisma.log.findMany.mockResolvedValue([
        { caloriesIntake: 200 },
        { caloriesIntake: 300 },
        { caloriesIntake: null },
      ] as any);
      const res = await service.getDailyIntake('user-1', '2025-01-10');
      expect(res).toEqual({ date: '2025-01-10', totalCaloriesIntake: 500 });
    });
  });

  describe('getMealTypeSummary', () => {
    it('returns zeros when no log', async () => {
      mockPrisma.log.findFirst.mockResolvedValue(null);
      const res = await service.getMealTypeSummary('user-1', '2025-01-10', MealType.LUNCH);
      expect(res).toEqual({ date: '2025-01-10', type: 'LUNCH', count: 0, totalCalories: 0 });
    });

    it('throws on invalid type', async () => {
      mockPrisma.log.findFirst.mockResolvedValue({ id: 'log-1' } as any);
      await expect(service.getMealTypeSummary('user-1', '2025-01-10', 'INVALID' as any)).rejects.toThrow(BadRequestException);
    });

    it('computes count and total', async () => {
      mockPrisma.log.findFirst.mockResolvedValue({ id: 'log-1' } as any);
      mockPrisma.meal.aggregate.mockResolvedValue({ _count: { _all: 2 }, _sum: { calories: 700 } } as any);
      const res = await service.getMealTypeSummary('user-1', '2025-01-10', MealType.DINNER);
      expect(res).toEqual({ date: '2025-01-10', type: 'DINNER', count: 2, totalCalories: 700 });
    });
  });

  describe('getAllMealTypesSummary', () => {
    it('returns zeros for all types when no log', async () => {
      mockPrisma.log.findFirst.mockResolvedValue(null);
      const res = await service.getAllMealTypesSummary('user-1', '2025-01-10');
      expect(res).toEqual({
        date: '2025-01-10',
        totalCaloriesIntake: 0,
        breakdown: expect.arrayContaining([
          { type: MealType.BREAKFAST, count: 0, totalCalories: 0 },
          { type: MealType.LUNCH, count: 0, totalCalories: 0 },
          { type: MealType.DINNER, count: 0, totalCalories: 0 },
          { type: MealType.SNACK, count: 0, totalCalories: 0 },
        ]),
      });
    });

    it('returns full breakdown and total from log', async () => {
      mockPrisma.log.findFirst.mockResolvedValue({ id: 'log-1', caloriesIntake: 1500 } as any);
      mockPrisma.meal.groupBy.mockResolvedValue([
        { type: MealType.BREAKFAST, _count: { _all: 1 }, _sum: { calories: 300 } },
        { type: MealType.LUNCH, _count: { _all: 2 }, _sum: { calories: 800 } },
      ] as any);
      const res = await service.getAllMealTypesSummary('user-1', '2025-01-10');
      expect(res.totalCaloriesIntake).toBe(1500);
      const map = new Map(res.breakdown.map((x: any) => [x.type, x]));
      expect(map.get(MealType.BREAKFAST)).toEqual({ type: MealType.BREAKFAST, count: 1, totalCalories: 300 });
      expect(map.get(MealType.LUNCH)).toEqual({ type: MealType.LUNCH, count: 2, totalCalories: 800 });
      // Types with no rows should be zeroed
      expect(map.get(MealType.DINNER)).toEqual({ type: MealType.DINNER, count: 0, totalCalories: 0 });
      expect(map.get(MealType.SNACK)).toEqual({ type: MealType.SNACK, count: 0, totalCalories: 0 });
    });
  });
});

