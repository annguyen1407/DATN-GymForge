import { ApiProperty } from '@nestjs/swagger';

export class PlanBriefDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty({ format: 'uuid' })
  userId!: string;
}

export class DayMetaDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid' })
  workoutPlanId!: string;

  @ApiProperty({ nullable: true, description: 'Day number in the workout plan; can be null for undated/unscheduled entries' })
  dayNumber!: number | null;

  @ApiProperty({ nullable: true, description: 'Scheduled calendar date if provided' })
  date!: string | Date | null;

  @ApiProperty({ enum: ['PENDING', 'COMPLETED', 'SKIPPED'], required: false })
  status?: 'PENDING' | 'COMPLETED' | 'SKIPPED';

  @ApiProperty({ nullable: true, required: false, description: 'Timestamp when the day was completed' })
  completedAt?: string | Date | null;
}

export class PlannedFieldsDto {
  @ApiProperty({ required: false, nullable: true })
  targetSets?: number | null;

  @ApiProperty({ required: false, nullable: true })
  targetReps?: number | null;

  @ApiProperty({ required: false, nullable: true })
  targetWeight?: number | null;

  @ApiProperty({ required: false, nullable: true })
  restTimeSec?: number | null;

  @ApiProperty({ required: false, nullable: true })
  timePerSetSec?: number | null;
}

export class WorkoutExerciseDayStatDto {
  @ApiProperty({ format: 'uuid' })
  workoutExerciseId!: string;

  @ApiProperty({ format: 'uuid' })
  exerciseId!: string;

  @ApiProperty({ type: PlannedFieldsDto })
  planned!: PlannedFieldsDto;

  @ApiProperty()
  logsCount!: number;

  @ApiProperty({ nullable: true })
  avgProgressPercent!: number | null;

  @ApiProperty()
  totalCaloriesBurned!: number;
}

export class DayStatsResponseDto {
  @ApiProperty({ type: PlanBriefDto, nullable: true })
  workoutPlan!: PlanBriefDto | null;

  @ApiProperty({ type: DayMetaDto })
  day!: DayMetaDto;

  @ApiProperty({ type: [WorkoutExerciseDayStatDto] })
  stats!: WorkoutExerciseDayStatDto[];
}

