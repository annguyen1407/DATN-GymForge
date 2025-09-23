-- CreateEnum
CREATE TYPE "public"."DayStatus" AS ENUM ('PENDING', 'COMPLETED', 'SKIPPED');

-- AlterTable
ALTER TABLE "public"."workout_days" ADD COLUMN     "completedAt" TIMESTAMP(3),
ADD COLUMN     "status" "public"."DayStatus" DEFAULT 'PENDING';

-- CreateIndex
CREATE INDEX "workout_days_status_idx" ON "public"."workout_days"("status");
