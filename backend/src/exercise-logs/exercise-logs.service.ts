import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateExerciseLogDto } from './dto/create-exercise-log.dto';
import { UpdateExerciseLogDto } from './dto/update-exercise-log.dto';
import { QuickLogExerciseDto } from './dto/quick-log-exercise.dto';
import { UpdateDailyLogDto } from './dto/update-daily-log.dto';
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

    // Verify workout exercise exists
    {
      const workoutExercise = await this.prisma.workoutExercise.findUnique({
        where: { id: createExerciseLogDto.workoutExerciseId },
      });
      if (!workoutExercise) {
        throw new NotFoundException('Workout exercise not found');
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
          weight: user.weight ?? undefined,
          height: user.height ?? undefined,
        },
      });
    } else {
      // Update existing log with additional calories
      await this.prisma.log.update({
        where: { id: log.id },
        data: {
          caloriesBurned: (log.caloriesBurned || 0) + (createExerciseLogDto.totalCaloriesBurned || 0),
          notes: createExerciseLogDto.notes ? `${log.notes || ''}\n${createExerciseLogDto.notes}` : log.notes,
          weight: user.weight ?? undefined,
          height: user.height ?? undefined,
        },
      });
    }

    // Calculate total time (seconds) for this exercise from sets.times
    const totalTimeSec = (sets || []).reduce((sum, s) => sum + (s.times || 0), 0);

    // Create workout exercise log first
    const wel = await this.prisma.workoutExerciseLog.create({
      data: {
        logId: log.id,
        workoutExerciseId: createExerciseLogDto.workoutExerciseId,
        date: new Date(createExerciseLogDto.date),
        progressPercent: createExerciseLogDto.progressPercent,
        caloriesBurned: createExerciseLogDto.totalCaloriesBurned,
        dayNumber: createExerciseLogDto.dayNumber,
        totalTime: totalTimeSec,
      },
    });

    // Create sets logs if provided and attach to the WEL
    if (sets && sets.length > 0) {
      await this.prisma.setsLog.createMany({
        data: sets.map(set => ({
          workoutExerciseLogId: wel.id,
          setNumber: set.setNumber,
          reps: set.reps,
          times: set.times,
          weight: set.weight,
          caloriesBurned: set.caloriesBurned,
        })),
      });
    }

    // Update total workout time on the day log
    await this.prisma.log.update({
      where: { id: log.id },
      data: {
        totalWorkoutTime: (log.totalWorkoutTime || 0) + totalTimeSec,
      },
    });

    // Auto-mark workout day as completed when all exercises in that day have logs for this user/date
    try {
      const we = await this.prisma.workoutExercise.findUnique({
        where: { id: createExerciseLogDto.workoutExerciseId },
        select: { workoutDayId: true },
      });

      const dayId = we?.workoutDayId;
      if (dayId) {
        const totalExercises = await this.prisma.workoutExercise.count({
          where: { workoutDayId: dayId },
        });

        if (totalExercises > 0) {
          const completed = await this.prisma.workoutExerciseLog.groupBy({
            by: ['workoutExerciseId'],
            where: {
              logId: log.id,
              workoutExercise: { workoutDayId: dayId },
            },
            _count: { _all: true },
          });

          const distinctCompleted = completed.length;

          if (distinctCompleted >= totalExercises) {
            await this.prisma.workoutDay.update({
              where: { id: dayId },
              data: {
                status: 'COMPLETED' as any,
                completedAt: new Date(createExerciseLogDto.date),
              }
            });
          }
        }
      }
    } catch (err) {
      // Non-fatal: logging should not fail if status update fails
    }

    // Return created WEL plus sets and computed totalTime
    const setsCreated = await this.prisma.setsLog.findMany({
      where: { workoutExerciseLogId: wel.id },
      orderBy: { setNumber: 'asc' },
    });
    return { ...wel, sets: setsCreated } as any;
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
        totalCaloriesIntake: 0,
        totalWorkoutTime: 0,
        averageWeight: 0,
        workoutPlansCompleted: [],
      };
    }

    // Collect WorkoutExerciseLog IDs for the day
    const welIds = logs.flatMap(lg => (lg.workoutExerciseLogs || []).map((w: any) => w.id));
    const totalExercises = welIds.length;

    const daySets = welIds.length > 0
      ? await this.prisma.setsLog.findMany({ where: { workoutExerciseLogId: { in: welIds } } })
      : [];

    const totalSets = daySets.length;
    const totalReps = daySets.reduce((sum, set) => sum + (set.reps || 0), 0);
    const totalCaloriesBurned = logs.reduce((sum, log) => sum + (log.caloriesBurned || 0), 0);

    // Total workout time (seconds): prefer aggregated field on Log, fallback to sum of workoutExerciseLogs.totalTime
    const totalWorkoutTimeSec = logs.reduce((sum, lg: any) => {
      const fromLog = lg.totalWorkoutTime ?? 0; // stored as seconds in DB
      const fromEntries = (lg.workoutExerciseLogs || []).reduce((s: number, wel: any) => s + (wel.totalTime || 0), 0);
      return sum + (fromLog || fromEntries);
    }, 0);
    const totalWorkoutTime = Math.round(totalWorkoutTimeSec / 60);

    const allWeights = daySets.map(set => set.weight).filter(weight => weight !== null && weight !== undefined);
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
      totalCaloriesIntake: logs.reduce((sum, l) => sum + (l.caloriesIntake || 0), 0),
      totalWorkoutTime,
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
      totalWorkoutTime,
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

    // Compute total workout time (minutes) for the month
    const totalWorkoutTimeSec = logs.reduce((sum, lg: any) => {
      const fromLog = lg.totalWorkoutTime ?? 0;
      const fromEntries = (lg.workoutExerciseLogs || []).reduce((s: number, wel: any) => s + (wel.totalTime || 0), 0);
      return sum + (fromLog || fromEntries);
    }, 0);
    const totalWorkoutTime = Math.round(totalWorkoutTimeSec / 60);

    // Total exercises in the month = number of WorkoutExerciseLog entries in the period
    const totalExercises = logs.reduce((sum, lg: any) => sum + ((lg.workoutExerciseLogs?.length) || 0), 0);

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
      totalWorkoutTime,
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

      // Get all sets for this exercise (across the matched WELs)
      const allSets = await this.prisma.setsLog.findMany({
        where: {
          workoutExerciseLogId: { in: logs.map(log => log.id) },
        },
      });

      const recentIds = new Set(logs.slice(0, 3).map(l => l.id));
      const olderIds = new Set(logs.slice(-3).map(l => l.id));

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
        const recentWeights = allSets
          .filter(s => recentIds.has(s.workoutExerciseLogId))
          .map(s => s.weight)
          .filter(w => w !== null && w !== undefined);

        const olderWeights = allSets
          .filter(s => olderIds.has(s.workoutExerciseLogId))
          .map(s => s.weight)
          .filter(w => w !== null && w !== undefined);

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
    // Resolve exercise info from workoutExerciseId
    const workoutExercise = await this.prisma.workoutExercise.findUnique({
      where: { id: quickLogDto.workoutExerciseId },
      select: { exerciseId: true, dayNumber: true },
    });

    if (!workoutExercise) {
      throw new NotFoundException('Workout exercise not found');
    }

    let exercise: any = null;
    if (workoutExercise.exerciseId) {
      exercise = await this.prisma.exercise.findUnique({
        where: { id: workoutExercise.exerciseId },
      });
    }

    // Calculate total calories burned (simplified calculation)
    const totalReps = quickLogDto.sets.reduce((sum, set) => sum + set.reps, 0);
    const averageWeight = quickLogDto.sets.reduce((sum, set) => sum + (set.weight || 0), 0) / quickLogDto.sets.length;
    const estimatedCalories = (exercise?.met ?? 3.5) * (averageWeight / 10) * (totalReps / 10);

    // Create the full exercise log
    const createLogDto: CreateExerciseLogDto = {
      userId,
      workoutExerciseId: quickLogDto.workoutExerciseId,
      dayNumber: quickLogDto.dayNumber ?? (workoutExercise.dayNumber ?? undefined),
      date: new Date().toISOString().split('T')[0],
      exerciseName: exercise?.name || undefined,
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


  // Fetch a WorkoutExerciseLog by its ID with context
  async findWorkoutExerciseLogById(id: string) {
    const wel = await this.prisma.workoutExerciseLog.findUnique({
      where: { id },
      include: {
        workoutExercise: {
          include: {
            workoutPlan: { select: { id: true, name: true } },
            workoutDay: { select: { id: true, dayNumber: true, date: true } },
          },
        },
        log: true,
      },
    });

    if (!wel) throw new NotFoundException('Workout exercise log not found');
    return wel;
  }

  // Update a WorkoutExerciseLog and its sets
  async updateWorkoutExerciseLog(id: string, dto: UpdateExerciseLogDto) {
    const wel = await this.prisma.workoutExerciseLog.findUnique({ where: { id } });
    if (!wel) throw new NotFoundException('Workout exercise log not found');

    let totalTimeSec: number | undefined = undefined;
    if (dto.sets) {
      await this.prisma.setsLog.deleteMany({ where: { workoutExerciseLogId: id } });
      if (dto.sets.length > 0) {
        await this.prisma.setsLog.createMany({
          data: dto.sets.map(s => ({
            workoutExerciseLogId: id,
            setNumber: s.setNumber,
            reps: s.reps,
            times: s.times,
            weight: s.weight,
            caloriesBurned: s.caloriesBurned,
          })),
        });
      }
      totalTimeSec = dto.sets.reduce((sum, s) => sum + (s.times || 0), 0);
    }

    const data: any = {};
    if (dto.progressPercent !== undefined) data.progressPercent = dto.progressPercent;
    if (dto.totalCaloriesBurned !== undefined) data.caloriesBurned = dto.totalCaloriesBurned;
    if (dto.dayNumber !== undefined) data.dayNumber = dto.dayNumber;
    if (dto.date) data.date = new Date(dto.date);
    if (dto.workoutExerciseId) data.workoutExerciseId = dto.workoutExerciseId;
    if (totalTimeSec !== undefined) data.totalTime = totalTimeSec;

    const updated = await this.prisma.workoutExerciseLog.update({ where: { id }, data });

    // Recompute parent day's total workout time (seconds)
    const siblings = await this.prisma.workoutExerciseLog.findMany({ where: { logId: updated.logId } });
    const sumTime = siblings.reduce((sum, w) => sum + (w.totalTime || 0), 0);
    await this.prisma.log.update({ where: { id: updated.logId }, data: { totalWorkoutTime: sumTime } });

    const sets = await this.prisma.setsLog.findMany({ where: { workoutExerciseLogId: id }, orderBy: { setNumber: 'asc' } });
    return { ...updated, sets } as any;
  }

  // Delete a WorkoutExerciseLog by id
  async deleteWorkoutExerciseLog(id: string) {
    const wel = await this.prisma.workoutExerciseLog.findUnique({ where: { id } });
    if (!wel) throw new NotFoundException('Workout exercise log not found');
    await this.prisma.workoutExerciseLog.delete({ where: { id } });
    // Recompute parent day's total workout time
    const siblings = await this.prisma.workoutExerciseLog.findMany({ where: { logId: wel.logId } });
    const sumTime = siblings.reduce((sum, w) => sum + (w.totalTime || 0), 0);
    await this.prisma.log.update({ where: { id: wel.logId }, data: { totalWorkoutTime: sumTime } });
    return { id };
  }

  // List all Set logs for a WorkoutExerciseLog
  async listSetsByWorkoutExerciseLog(id: string) {
    return this.prisma.setsLog.findMany({
      where: { workoutExerciseLogId: id },
      orderBy: { setNumber: 'asc' },
    });
  }


  // Daily Log CRUD (by user + date)
  async upsertDailyLog(userId: string, date: string, dto: UpdateDailyLogDto) {
    const targetDate = new Date(date);
    const existing = await this.prisma.log.findFirst({ where: { userId, dateLogged: targetDate } });
    if (existing) {
      return this.prisma.log.update({ where: { id: existing.id }, data: { ...dto } });
    }
    return this.prisma.log.create({
      data: {
        userId,
        dateLogged: targetDate,
        notes: dto.notes,
        caloriesBurned: dto.caloriesBurned,
        caloriesIntake: dto.caloriesIntake,
        weight: dto.weight,
        height: dto.height,
      },
    });
  }

  async getDailyLog(userId: string, date: string) {
    const targetDate = new Date(date);
    const log = await this.prisma.log.findFirst({
      where: { userId, dateLogged: targetDate },
      include: {
        meals: true,
        workoutExerciseLogs: true,
      },
    });
    if (!log) throw new NotFoundException('Daily log not found');
    return log;
  }

  async updateDailyLog(userId: string, date: string, dto: UpdateDailyLogDto) {
    const targetDate = new Date(date);
    const existing = await this.prisma.log.findFirst({ where: { userId, dateLogged: targetDate } });
    if (!existing) throw new NotFoundException('Daily log not found');
    return this.prisma.log.update({ where: { id: existing.id }, data: { ...dto } });
  }

  async deleteDailyLog(userId: string, date: string) {
    const targetDate = new Date(date);
    const existing = await this.prisma.log.findFirst({ where: { userId, dateLogged: targetDate } });
    if (!existing) throw new NotFoundException('Daily log not found');
    return this.prisma.log.delete({ where: { id: existing.id } });
  }

}
