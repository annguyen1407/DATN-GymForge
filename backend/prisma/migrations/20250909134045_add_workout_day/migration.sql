-- AlterTable
ALTER TABLE "public"."workout_exercises" ADD COLUMN     "workoutDayId" UUID;

-- CreateTable
CREATE TABLE "public"."workout_days" (
    "id" UUID NOT NULL,
    "workoutPlanId" UUID NOT NULL,
    "dayNumber" INTEGER,
    "date" DATE,

    CONSTRAINT "workout_days_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "public"."workout_days" ADD CONSTRAINT "workout_days_workoutPlanId_fkey" FOREIGN KEY ("workoutPlanId") REFERENCES "public"."workout_plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."workout_exercises" ADD CONSTRAINT "workout_exercises_workoutDayId_fkey" FOREIGN KEY ("workoutDayId") REFERENCES "public"."workout_days"("id") ON DELETE SET NULL ON UPDATE CASCADE;
