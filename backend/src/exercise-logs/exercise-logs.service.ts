import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateExerciseLogDto } from './dto/create-exercise-log.dto';
import { UpdateExerciseLogDto } from './dto/update-exercise-log.dto';
import { QuickLogExerciseDto } from './dto/quick-log-exercise.dto';
import {
  DailyExerciseStatsDto,
  WeeklyExerciseStatsDto,
  MonthlyExerciseStatsDto,
  WorkoutPlanProgressDto,
  ExercisePerformanceDto,
} from './dto/exercise-statistics.dto';

@Injectable()
export class ExerciseLogsService {
  constructor(private prisma: PrismaService) {}

  async createExerciseLog(createExerciseLogDto: CreateExerciseLogDto) {
    const { sets, ...logData } = createExerciseLogDto;

    // Verify user exists
    const user = await this.prisma.user.findUnique({
      where: { id: createExerciseLogDto.userId },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Verify exercise exists if exerciseId is provided
    if (createExerciseLogDto.exerciseId) {
      const exercise = await this.prisma.exercise.findUnique({
        where: { id: createExerciseLogDto.exerciseId },
      });
      if (!exercise) {
        throw new NotFoundException('Exercise not found');
      }
    }

    // Verify workout plan exists if workoutPlanId is provided
    if (createExerciseLogDto.workoutPlanId) {
      const workoutPlan = await this.prisma.workoutPlan.findUnique({
        where: { id: createExerciseLogDto.workoutPlanId },
      });
      if (!workoutPlan) {
        throw new NotFoundException('Workout plan not found');
      }
    }

    // Create or find existing log for the date
    let log = await this.prisma.log.findFirst({
      where: {
        userId: createExerciseLogDto.userId,
        dateLogged: new Date(createExerciseLogDto.date),
      },
    });

    if (!log) {
      log = await this.prisma.log.create({
        data: {
          userId: createExerciseLogDto.userId,
          dateLogged: new Date(createExerciseLogDto.date),
          caloriesBurned: createExerciseLogDto.totalCaloriesBurned || 0,
          notes: createExerciseLogDto.notes,
        },
      });
    } else {
      // Update existing log with additional calories
      await this.prisma.log.update({
        where: { id: log.id },
        data: {
          caloriesBurned: (log.caloriesBurned || 0) + (createExerciseLogDto.totalCaloriesBurned || 0),
          notes: createExerciseLogDto.notes ? `${log.notes || ''}\n${createExerciseLogDto.notes}` : log.notes,
        },
      });
    }

    // Create exercise log
    const exerciseLog = await this.prisma.exerciseLog.create({
      data: {
        workoutLogId: log.id,
      },
    });

    // Create sets logs if provided
    if (sets && sets.length > 0) {
      await this.prisma.setsLog.createMany({
        data: sets.map(set => ({
          exerciseLogId: exerciseLog.id,
          setNumber: set.setNumber,
          reps: set.reps,
          times: set.times,
          weight: set.weight,
          caloriesBurned: set.caloriesBurned,
        })),
      });
    }

    // Create workout exercise log if part of a workout plan
    if (createExerciseLogDto.workoutPlanId) {
      await this.prisma.workoutExerciseLog.create({
        data: {
          logId: log.id,
          workoutExerciseId: createExerciseLogDto.exerciseId || '',
          date: new Date(createExerciseLogDto.date),
          progressPercent: createExerciseLogDto.progressPercent,
          caloriesBurned: createExerciseLogDto.totalCaloriesBurned,
          dayNumber: createExerciseLogDto.dayNumber,
        },
      });
    }

    return this.findExerciseLogById(exerciseLog.id);
  }

  async findExerciseLogById(id: string) {
    const exerciseLog = await this.prisma.exerciseLog.findUnique({
      where: { id },
      include: {
        setsLog: {
          orderBy: { setNumber: 'asc' },
        },
      },
    });

    if (!exerciseLog) {
      throw new NotFoundException('Exercise log not found');
    }

    return exerciseLog;
  }

  async findUserExerciseLogs(userId: string, startDate?: string, endDate?: string) {
    const where: any = {
      userId,
    };

    if (startDate || endDate) {
      where.dateLogged = {};
      if (startDate) where.dateLogged.gte = new Date(startDate);
      if (endDate) where.dateLogged.lte = new Date(endDate);
    }

    return this.prisma.log.findMany({
      where,
      include: {
        workoutExerciseLogs: {
          include: {
            workoutExercise: {
              include: {
                workoutPlan: {
                  select: {
                    id: true,
                    name: true,
                    planType: true,
                  },
                },
              },
            },
          },
        },
      },
      orderBy: { dateLogged: 'desc' },
    });
  }

  async updateExerciseLog(id: string, updateExerciseLogDto: UpdateExerciseLogDto) {
    const exerciseLog = await this.findExerciseLogById(id);
    
    // Update sets if provided
    if (updateExerciseLogDto.sets) {
      // Delete existing sets
      await this.prisma.setsLog.deleteMany({
        where: { exerciseLogId: id },
      });

      // Create new sets
      if (updateExerciseLogDto.sets.length > 0) {
        await this.prisma.setsLog.createMany({
          data: updateExerciseLogDto.sets.map(set => ({
            exerciseLogId: id,
            setNumber: set.setNumber,
            reps: set.reps,
            times: set.times,
            weight: set.weight,
            caloriesBurned: set.caloriesBurned,
          })),
        });
      }
    }

    return this.findExerciseLogById(id);
  }

  async deleteExerciseLog(id: string) {
    const exerciseLog = await this.findExerciseLogById(id);

    // Delete sets first
    await this.prisma.setsLog.deleteMany({
      where: { exerciseLogId: id },
    });

    // Delete exercise log
    return this.prisma.exerciseLog.delete({
      where: { id },
    });
  }

  async getDailyStats(userId: string, date: string): Promise<DailyExerciseStatsDto> {
    const targetDate = new Date(date);
    
    const logs = await this.prisma.log.findMany({
      where: {
        userId,
        dateLogged: targetDate,
      },
      include: {
        workoutExerciseLogs: {
          include: {
            workoutExercise: {
              include: {
                workoutPlan: {
                  select: {
                    name: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (logs.length === 0) {
      return {
        date,
        totalExercises: 0,
        totalSets: 0,
        totalReps: 0,
        totalCaloriesBurned: 0,
        totalWorkoutTime: 0,
        averageWeight: 0,
        workoutPlansCompleted: [],
      };
    }

    // Get all exercise logs for the day
    const exerciseLogs = await this.prisma.exerciseLog.findMany({
      where: {
        workoutLogId: { in: logs.map(log => log.id) },
      },
      include: {
        setsLog: true,
      },
    });

    const totalExercises = exerciseLogs.length;
    const totalSets = exerciseLogs.reduce((sum, log) => sum + log.setsLog.length, 0);
    const totalReps = exerciseLogs.reduce((sum, log) => 
      sum + log.setsLog.reduce((setSum, set) => setSum + (set.reps || 0), 0), 0);
    const totalCaloriesBurned = logs.reduce((sum, log) => sum + (log.caloriesBurned || 0), 0);
    
    const allWeights = exerciseLogs.flatMap(log => 
      log.setsLog.map(set => set.weight).filter(weight => weight !== null && weight !== undefined)
    );
    const averageWeight = allWeights.length > 0 ? 
      allWeights.reduce((sum, weight) => sum + weight, 0) / allWeights.length : 0;

    const workoutPlansCompleted = [
      ...new Set(
        logs.flatMap(log =>
          log.workoutExerciseLogs.map(wel => wel.workoutExercise?.workoutPlan?.name).filter(Boolean)
        )
      )
    ].filter((name): name is string => typeof name === 'string');

    return {
      date,
      totalExercises,
      totalSets,
      totalReps,
      totalCaloriesBurned,
      totalWorkoutTime: 0, // This would need additional tracking
      averageWeight,
      workoutPlansCompleted,
    };
  }

  async getWeeklyStats(userId: string, weekStart: string): Promise<WeeklyExerciseStatsDto> {
    const startDate = new Date(weekStart);
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 6);

    const dailyStats: DailyExerciseStatsDto[] = [];
    let totalWorkoutDays = 0;
    let totalExercises = 0;
    let totalCaloriesBurned = 0;
    let totalWorkoutTime = 0;

    // Get stats for each day of the week
    for (let i = 0; i < 7; i++) {
      const currentDate = new Date(startDate);
      currentDate.setDate(currentDate.getDate() + i);
      const dateStr = currentDate.toISOString().split('T')[0];

      const dayStats = await this.getDailyStats(userId, dateStr);
      dailyStats.push(dayStats);

      if (dayStats.totalExercises > 0) {
        totalWorkoutDays++;
        totalExercises += dayStats.totalExercises;
        totalCaloriesBurned += dayStats.totalCaloriesBurned;
        totalWorkoutTime += dayStats.totalWorkoutTime;
      }
    }

    return {
      weekStart: startDate.toISOString().split('T')[0],
      weekEnd: endDate.toISOString().split('T')[0],
      totalWorkoutDays,
      totalExercises,
      totalCaloriesBurned,
      averageDailyWorkoutTime: totalWorkoutDays > 0 ? totalWorkoutTime / totalWorkoutDays : 0,
      dailyStats,
    };
  }

  async getMonthlyStats(userId: string, month: string): Promise<MonthlyExerciseStatsDto> {
    const [year, monthNum] = month.split('-').map(Number);
    const startDate = new Date(year, monthNum - 1, 1);
    const endDate = new Date(year, monthNum, 0);

    const logs = await this.prisma.log.findMany({
      where: {
        userId,
        dateLogged: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        workoutExerciseLogs: {
          include: {
            workoutExercise: {
              include: {
                workoutPlan: {
                  select: {
                    name: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    const totalWorkoutDays = logs.length;
    const totalCaloriesBurned = logs.reduce((sum, log) => sum + (log.caloriesBurned || 0), 0);

    // Get exercise logs for the month
    const exerciseLogs = await this.prisma.exerciseLog.findMany({
      where: {
        workoutLogId: { in: logs.map(log => log.id) },
      },
      include: {
        setsLog: true,
      },
    });

    const totalExercises = exerciseLogs.length;

    // Calculate most performed exercises (this would need exercise name tracking)
    const mostPerformedExercises: { name: string; count: number }[] = [];

    // Calculate weekly stats
    const weeklyStats: WeeklyExerciseStatsDto[] = [];
    const weeksInMonth = Math.ceil(endDate.getDate() / 7);

    for (let week = 0; week < weeksInMonth; week++) {
      const weekStartDate = new Date(startDate);
      weekStartDate.setDate(weekStartDate.getDate() + (week * 7));
      const weekStartStr = weekStartDate.toISOString().split('T')[0];

      const weekStats = await this.getWeeklyStats(userId, weekStartStr);
      weeklyStats.push(weekStats);
    }

    return {
      month,
      totalWorkoutDays,
      totalExercises,
      totalCaloriesBurned,
      averageWeeklyFrequency: totalWorkoutDays / 4, // Approximate weeks in month
      mostPerformedExercises,
      weeklyStats,
    };
  }

  async getWorkoutPlanProgress(userId: string, workoutPlanId: string): Promise<WorkoutPlanProgressDto> {
    const workoutPlan = await this.prisma.workoutPlan.findUnique({
      where: { id: workoutPlanId },
      include: {
        exercises: {
          include: {
            WorkoutExerciseLog: {
              where: {
                log: {
                  userId,
                },
              },
              orderBy: { date: 'asc' },
            },
          },
        },
      },
    });

    if (!workoutPlan) {
      throw new NotFoundException('Workout plan not found');
    }

    const totalDays = workoutPlan.days || 0;
    const exerciseLogs = workoutPlan.exercises.flatMap(ex => ex.WorkoutExerciseLog);

    // Group logs by day
    const dayProgress = new Map<number, any>();

    exerciseLogs.forEach(log => {
      const day = log.dayNumber || 1;
      if (!dayProgress.has(day)) {
        dayProgress.set(day, {
          dayNumber: day,
          date: log.date?.toISOString().split('T')[0] || '',
          completed: false,
          exercisesCompleted: 0,
          totalExercises: workoutPlan.exercises.filter(ex =>
            ex.dayNumber === day || ex.dayNumber === null
          ).length,
          progressPercent: 0,
        });
      }

      const dayData = dayProgress.get(day);
      dayData.exercisesCompleted++;
      dayData.progressPercent = (dayData.exercisesCompleted / dayData.totalExercises) * 100;
      dayData.completed = dayData.progressPercent >= 100;
    });

    const dailyProgress = Array.from(dayProgress.values()).sort((a, b) => a.dayNumber - b.dayNumber);
    const daysCompleted = dailyProgress.filter(day => day.completed).length;
    const overallProgress = totalDays > 0 ? (daysCompleted / totalDays) * 100 : 0;

    // Find start date and calculate expected completion
    const firstLog = exerciseLogs.sort((a, b) =>
      new Date(a.date || 0).getTime() - new Date(b.date || 0).getTime()
    )[0];

    const startDate = firstLog?.date?.toISOString().split('T')[0] || new Date().toISOString().split('T')[0];
    const expectedCompletionDate = new Date(startDate);
    expectedCompletionDate.setDate(expectedCompletionDate.getDate() + totalDays);

    return {
      workoutPlanId,
      planName: workoutPlan.name || 'Unnamed Plan',
      overallProgress,
      totalDays,
      daysCompleted,
      currentDay: Math.max(...dailyProgress.map(d => d.dayNumber), 0) + 1,
      startDate,
      expectedCompletionDate: expectedCompletionDate.toISOString().split('T')[0],
      dailyProgress,
    };
  }

  async getExercisePerformance(userId: string, exerciseId?: string): Promise<ExercisePerformanceDto[]> {
    const where: any = {
      log: {
        userId,
      },
    };

    if (exerciseId) {
      where.workoutExercise = {
        exerciseId,
      };
    }

    const workoutExerciseLogs = await this.prisma.workoutExerciseLog.findMany({
      where,
      include: {
        workoutExercise: {
          include: {
            workoutPlan: {
              select: {
                name: true,
              },
            },
          },
        },
        log: {
          include: {
            workoutExerciseLogs: {
              include: {
                workoutExercise: true,
              },
            },
          },
        },
      },
      orderBy: { date: 'desc' },
    });

    // Group by exercise
    const exerciseGroups = new Map<string, any[]>();

    workoutExerciseLogs.forEach(log => {
      const key = log.workoutExercise?.exerciseId || 'unknown';
      if (!exerciseGroups.has(key)) {
        exerciseGroups.set(key, []);
      }
      exerciseGroups.get(key)!.push(log);
    });

    const performances: ExercisePerformanceDto[] = [];

    for (const [exerciseKey, logs] of exerciseGroups) {
      if (exerciseKey === 'unknown') continue;

      // Get exercise details
      const exercise = await this.prisma.exercise.findUnique({
        where: { id: exerciseKey },
        select: { name: true },
      });

      const exerciseName = exercise?.name || 'Unknown Exercise';
      const totalSessions = logs.length;

      // Get all sets for this exercise
      const allSets = await this.prisma.setsLog.findMany({
        where: {
          exerciseLog: {
            workoutLogId: { in: logs.map(log => log.logId) },
          },
        },
      });

      const weights = allSets.map(set => set.weight).filter(w => w !== null && w !== undefined);
      const reps = allSets.map(set => set.reps).filter(r => r !== null && r !== undefined);

      const bestWeight = weights.length > 0 ? Math.max(...weights) : 0;
      const bestReps = reps.length > 0 ? Math.max(...reps) : 0;
      const averageWeight = weights.length > 0 ? weights.reduce((sum, w) => sum + w, 0) / weights.length : 0;
      const averageReps = reps.length > 0 ? reps.reduce((sum, r) => sum + r, 0) / reps.length : 0;

      const totalCaloriesBurned = logs.reduce((sum, log) => sum + (log.caloriesBurned || 0), 0);
      const lastPerformed = logs[0]?.date?.toISOString().split('T')[0] || '';

      // Simple progress trend calculation
      let progressTrend = 'stable';
      if (logs.length >= 2) {
        // Note: We need to get sets for specific exercise logs, but the current schema doesn't directly link
        // For now, we'll use a simpler approach based on recent vs older logs
        const recentLogs = logs.slice(0, 3);
        const olderLogs = logs.slice(-3);

        const recentWeights = allSets.filter(set =>
          recentLogs.some(log => log.logId === log.logId)
        ).map(set => set.weight).filter(w => w !== null && w !== undefined);

        const olderWeights = allSets.filter(set =>
          olderLogs.some(log => log.logId === log.logId)
        ).map(set => set.weight).filter(w => w !== null && w !== undefined);

        if (recentWeights.length > 0 && olderWeights.length > 0) {
          const recentAvg = recentWeights.reduce((sum, w) => sum + w, 0) / recentWeights.length;
          const olderAvg = olderWeights.reduce((sum, w) => sum + w, 0) / olderWeights.length;

          if (recentAvg > olderAvg * 1.05) progressTrend = 'positive';
          else if (recentAvg < olderAvg * 0.95) progressTrend = 'negative';
        }
      }

      performances.push({
        exerciseId: exerciseKey,
        exerciseName,
        totalSessions,
        bestWeight,
        bestReps,
        averageWeight,
        averageReps,
        totalCaloriesBurned,
        progressTrend,
        lastPerformed,
      });
    }

    return performances.sort((a, b) => b.totalSessions - a.totalSessions);
  }

  async getUserWorkoutPlansProgress(userId: string): Promise<WorkoutPlanProgressDto[]> {
    const userWorkoutPlans = await this.prisma.workoutPlan.findMany({
      where: { userId },
      select: { id: true },
    });

    const progressPromises = userWorkoutPlans.map(plan =>
      this.getWorkoutPlanProgress(userId, plan.id)
    );

    return Promise.all(progressPromises);
  }

  async getExerciseStreaks(userId: string): Promise<{
    currentStreak: number;
    longestStreak: number;
    lastWorkoutDate: string | null;
  }> {
    const logs = await this.prisma.log.findMany({
      where: { userId },
      orderBy: { dateLogged: 'desc' },
      select: { dateLogged: true },
    });

    if (logs.length === 0) {
      return {
        currentStreak: 0,
        longestStreak: 0,
        lastWorkoutDate: null,
      };
    }

    const dates = logs.map(log => log.dateLogged!).sort((a, b) => b.getTime() - a.getTime());
    const lastWorkoutDate = dates[0].toISOString().split('T')[0];

    let currentStreak = 0;
    let longestStreak = 0;
    let tempStreak = 0;

    // Calculate current streak
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (let i = 0; i < dates.length; i++) {
      const logDate = new Date(dates[i]);
      logDate.setHours(0, 0, 0, 0);

      const daysDiff = Math.floor((today.getTime() - logDate.getTime()) / (1000 * 60 * 60 * 24));

      if (i === 0 && daysDiff <= 1) {
        currentStreak = 1;
      } else if (i > 0) {
        const prevDate = new Date(dates[i - 1]);
        prevDate.setHours(0, 0, 0, 0);
        const daysBetween = Math.floor((prevDate.getTime() - logDate.getTime()) / (1000 * 60 * 60 * 24));

        if (daysBetween === 1) {
          if (i === 1 && currentStreak > 0) currentStreak++;
        } else {
          break;
        }
      }
    }

    // Calculate longest streak
    tempStreak = 1;
    for (let i = 1; i < dates.length; i++) {
      const currentDate = new Date(dates[i]);
      const prevDate = new Date(dates[i - 1]);
      const daysBetween = Math.floor((prevDate.getTime() - currentDate.getTime()) / (1000 * 60 * 60 * 24));

      if (daysBetween === 1) {
        tempStreak++;
      } else {
        longestStreak = Math.max(longestStreak, tempStreak);
        tempStreak = 1;
      }
    }
    longestStreak = Math.max(longestStreak, tempStreak);

    return {
      currentStreak,
      longestStreak,
      lastWorkoutDate,
    };
  }

  async quickLogExercise(userId: string, quickLogDto: QuickLogExerciseDto) {
    // Get exercise details for calorie calculation
    const exercise = await this.prisma.exercise.findUnique({
      where: { id: quickLogDto.exerciseId },
    });

    if (!exercise) {
      throw new NotFoundException('Exercise not found');
    }

    // Calculate total calories burned (simplified calculation)
    const totalReps = quickLogDto.sets.reduce((sum, set) => sum + set.reps, 0);
    const averageWeight = quickLogDto.sets.reduce((sum, set) => sum + (set.weight || 0), 0) / quickLogDto.sets.length;
    const estimatedCalories = (exercise.met || 3.5) * (averageWeight / 10) * (totalReps / 10); // Simplified MET calculation

    // Create the full exercise log
    const createLogDto: CreateExerciseLogDto = {
      userId,
      exerciseId: quickLogDto.exerciseId,
      workoutPlanId: quickLogDto.workoutPlanId,
      dayNumber: quickLogDto.dayNumber,
      date: new Date().toISOString().split('T')[0],
      exerciseName: exercise.name || undefined,
      totalCaloriesBurned: estimatedCalories,
      notes: quickLogDto.notes,
      sets: quickLogDto.sets.map((set, index) => ({
        setNumber: index + 1,
        reps: set.reps,
        weight: set.weight,
        times: set.duration,
        caloriesBurned: estimatedCalories / quickLogDto.sets.length,
      })),
    };

    return this.createExerciseLog(createLogDto);
  }
}
