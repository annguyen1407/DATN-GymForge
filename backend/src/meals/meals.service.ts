import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AddMealForDayDto } from './dto/add-meal-for-day.dto';
import { UpdateMealDto } from './dto/update-meal.dto';
import { MealType } from '@prisma/client';

@Injectable()
export class MealsService {
  constructor(private prisma: PrismaService) {}


  async addMealForDay(userId: string, date: string, dto: AddMealForDayDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const targetDate = new Date(date);
    let log = await this.prisma.log.findFirst({ where: { userId, dateLogged: targetDate } });

    if (!log) {
      log = await this.prisma.log.create({
        data: {
          userId,
          dateLogged: targetDate,
          caloriesIntake: dto.calories || 0,
          weight: user.weight ?? undefined,
          height: user.height ?? undefined,
        },
      });
    } else {
      await this.prisma.log.update({
        where: { id: log.id },
        data: {
          caloriesIntake: (log.caloriesIntake || 0) + (dto.calories || 0),
          weight: user.weight ?? undefined,
          height: user.height ?? undefined,
        },
      });
    }

    const meal = await this.prisma.meal.create({
      data: {
        name: dto.name,
        calories: dto.calories,
        type: dto.type || undefined,
        date: targetDate,
        logId: log.id,
      },
    });

    return meal;
  }

  async listMealsForDay(userId: string, date: string) {
    const targetDate = new Date(date);
    const log = await this.prisma.log.findFirst({ where: { userId, dateLogged: targetDate } });
    if (!log) return [];

    const meals = await this.prisma.meal.findMany({ where: { logId: log.id } });
    return meals.map(m => ({ mealId: m.id, name: m.name, calories: m.calories, type: m.type }));
  }

  async deleteMeal(userId: string, date: string, mealId: string) {
    const meal = await this.prisma.meal.findUnique({ where: { id: mealId } });
    if (!meal) throw new NotFoundException('Meal not found');
    if (!meal.logId) throw new NotFoundException('Meal is not linked to a log');

    const targetDate = new Date(date);
    const log = await this.prisma.log.findUnique({ where: { id: meal.logId } });
    if (!log || log.userId !== userId || !log.dateLogged || log.dateLogged.getTime() !== targetDate.getTime()) {
      throw new NotFoundException('Log not found for this user and date');
    }

    const newTotal = Math.max(0, (log.caloriesIntake || 0) - (meal.calories || 0));

    await this.prisma.$transaction([
      this.prisma.meal.delete({ where: { id: mealId } }),
      this.prisma.log.update({ where: { id: log.id }, data: { caloriesIntake: newTotal } }),
    ]);

    return { ok: true };
  }

  async updateMeal(userId: string, date: string, mealId: string, dto: UpdateMealDto) {
    const meal = await this.prisma.meal.findUnique({ where: { id: mealId } });
    if (!meal) throw new NotFoundException('Meal not found');
    if (!meal.logId) throw new NotFoundException('Meal is not linked to a log');

    const targetDate = new Date(date);
    const log = await this.prisma.log.findUnique({ where: { id: meal.logId } });
    if (!log || log.userId !== userId || !log.dateLogged || log.dateLogged.getTime() !== targetDate.getTime()) {
      throw new NotFoundException('Log not found for this user and date');
    }

    const oldCal = meal.calories || 0;
    const newCal = dto.calories ?? oldCal;
    const newTotal = Math.max(0, (log.caloriesIntake || 0) - oldCal + newCal);

    const updatedMeal = await this.prisma.meal.update({
      where: { id: mealId },
      data: {
        name: dto.name ?? meal.name,
        calories: newCal,
        type: dto.type ?? meal.type,
      },
    });

    await this.prisma.log.update({ where: { id: log.id }, data: { caloriesIntake: newTotal } });
    return updatedMeal;
  }

  async getDailyIntake(userId: string, date: string) {
    const logs = await this.prisma.log.findMany({ where: { userId, dateLogged: new Date(date) } });
    const totalCaloriesIntake = logs.reduce((sum, l) => sum + (l.caloriesIntake || 0), 0);
    return { date, totalCaloriesIntake };
  }

  async getMealTypeSummary(userId: string, date: string, type: MealType | string) {
    const targetDate = new Date(date);
    const log = await this.prisma.log.findFirst({ where: { userId, dateLogged: targetDate } });
    if (!log) return { date, type, count: 0, totalCalories: 0 };

    const typeUpper = String(type).toUpperCase();
    if (!(typeUpper in MealType)) throw new BadRequestException('Invalid meal type');

    const agg = await this.prisma.meal.aggregate({
      where: { logId: log.id, type: typeUpper as MealType },
      _count: { _all: true },
      _sum: { calories: true },
    });

    const count = (agg as any)._count?._all ?? (agg as any)._count ?? 0;
    const totalCalories = (agg as any)._sum?.calories ?? 0;
    return { date, type: typeUpper, count, totalCalories };
  }

  async getAllMealTypesSummary(userId: string, date: string) {
    const targetDate = new Date(date);
    const log = await this.prisma.log.findFirst({ where: { userId, dateLogged: targetDate } });
    const types = Object.values(MealType) as MealType[];
    if (!log) {
      return {
        date,
        totalCaloriesIntake: 0,
        breakdown: types.map(t => ({ type: t, count: 0, totalCalories: 0 })),
      };
    }

    const rows = await this.prisma.meal.groupBy({
      by: ['type'],
      where: { logId: log.id },
      _count: { _all: true },
      _sum: { calories: true },
    });

    const map = new Map<MealType | null, { count: number; totalCalories: number }>();
    for (const r of rows as any[]) {
      const key = r.type as MealType | null;
      const count = r._count?._all ?? r._count ?? 0;
      const totalCalories = r._sum?.calories ?? 0;
      map.set(key, { count, totalCalories });
    }

    const totalCaloriesIntake = log.caloriesIntake || 0;
    return {
      date,
      totalCaloriesIntake,
      breakdown: types.map(t => {
        const m = map.get(t) || { count: 0, totalCalories: 0 };
        return { type: t, count: m.count, totalCalories: m.totalCalories };
      }),
    };
  }
}

