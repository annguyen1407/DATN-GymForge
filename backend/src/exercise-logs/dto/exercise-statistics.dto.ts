import { ApiProperty } from '@nestjs/swagger';

export class DailyExerciseStatsDto {
  @ApiProperty({ description: 'Date of the statistics', example: '2024-01-15' })
  date: string;

  @ApiProperty({ description: 'Total exercises performed', example: 5 })
  totalExercises: number;

  @ApiProperty({ description: 'Total sets performed', example: 25 })
  totalSets: number;

  @ApiProperty({ description: 'Total repetitions performed', example: 300 })
  totalReps: number;

  @ApiProperty({ description: 'Total calories burned', example: 450.5 })
  totalCaloriesBurned: number;

  @ApiProperty({ description: 'Total calories intake (meals) for the day', example: 1800 })
  totalCaloriesIntake: number;

  @ApiProperty({ description: 'Total workout time in minutes', example: 90 })
  totalWorkoutTime: number;

  @ApiProperty({ description: 'Average weight used across exercises', example: 45.5 })
  averageWeight: number;

  @ApiProperty({ description: 'Workout plans completed on this day', example: ['Plan A', 'Plan B'] })
  workoutPlansCompleted: string[];
}

export class WeeklyExerciseStatsDto {
  @ApiProperty({ description: 'Week start date', example: '2024-01-15' })
  weekStart: string;

  @ApiProperty({ description: 'Week end date', example: '2024-01-21' })
  weekEnd: string;

  @ApiProperty({ description: 'Total workout days in the week', example: 5 })
  totalWorkoutDays: number;

  @ApiProperty({ description: 'Total exercises performed in the week', example: 35 })
  totalExercises: number;

  @ApiProperty({ description: 'Total calories burned in the week', example: 2250.5 })
  totalCaloriesBurned: number;

  @ApiProperty({ description: 'Average daily workout time in minutes', example: 75 })
  averageDailyWorkoutTime: number;

  @ApiProperty({ description: 'Daily statistics breakdown', type: [DailyExerciseStatsDto] })
  dailyStats: DailyExerciseStatsDto[];
}

export class MonthlyExerciseStatsDto {
  @ApiProperty({ description: 'Month and year', example: '2024-01' })
  month: string;

  @ApiProperty({ description: 'Total workout days in the month', example: 20 })
  totalWorkoutDays: number;

  @ApiProperty({ description: 'Total exercises performed in the month', example: 150 })
  totalExercises: number;

  @ApiProperty({ description: 'Total calories burned in the month', example: 9500.5 })
  totalCaloriesBurned: number;

  @ApiProperty({ description: 'Average weekly workout frequency', example: 4.5 })
  averageWeeklyFrequency: number;

  @ApiProperty({ description: 'Most performed exercises', example: [{ name: 'Push-ups', count: 25 }] })
  mostPerformedExercises: { name: string; count: number }[];

  @ApiProperty({ description: 'Weekly statistics breakdown', type: [WeeklyExerciseStatsDto] })
  weeklyStats: WeeklyExerciseStatsDto[];
}

export class WorkoutPlanProgressDto {
  @ApiProperty({ description: 'Workout plan ID' })
  workoutPlanId: string;

  @ApiProperty({ description: 'Workout plan name', example: 'Beginner Strength Training' })
  planName: string;

  @ApiProperty({ description: 'Overall progress percentage', example: 75.5 })
  overallProgress: number;

  @ApiProperty({ description: 'Total days in the plan', example: 30 })
  totalDays: number;

  @ApiProperty({ description: 'Days completed', example: 22 })
  daysCompleted: number;

  @ApiProperty({ description: 'Current day in the plan', example: 23 })
  currentDay: number;

  @ApiProperty({ description: 'Start date of the plan', example: '2024-01-01' })
  startDate: string;

  @ApiProperty({ description: 'Expected completion date', example: '2024-01-30' })
  expectedCompletionDate: string;

  @ApiProperty({ description: 'Daily progress breakdown' })
  dailyProgress: {
    dayNumber: number;
    date: string;
    completed: boolean;
    exercisesCompleted: number;
    totalExercises: number;
    progressPercent: number;
  }[];
}

export class ExercisePerformanceDto {
  @ApiProperty({ description: 'Exercise ID' })
  exerciseId: string;

  @ApiProperty({ description: 'Exercise name', example: 'Bench Press' })
  exerciseName: string;

  @ApiProperty({ description: 'Total times performed', example: 15 })
  totalSessions: number;

  @ApiProperty({ description: 'Best weight lifted', example: 80.5 })
  bestWeight: number;

  @ApiProperty({ description: 'Best reps in a single set', example: 15 })
  bestReps: number;

  @ApiProperty({ description: 'Average weight across all sessions', example: 65.5 })
  averageWeight: number;

  @ApiProperty({ description: 'Average reps per set', example: 10.5 })
  averageReps: number;

  @ApiProperty({ description: 'Total calories burned from this exercise', example: 450.5 })
  totalCaloriesBurned: number;

  @ApiProperty({ description: 'Progress trend (positive/negative/stable)', example: 'positive' })
  progressTrend: string;

  @ApiProperty({ description: 'Last performed date', example: '2024-01-15' })
  lastPerformed: string;
}
