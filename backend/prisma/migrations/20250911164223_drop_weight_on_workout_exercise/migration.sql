/*
  Warnings:

  - You are about to drop the column `weight` on the `workout_exercises` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "public"."exercises" ADD COLUMN     "defaultTimePerSetSec" INTEGER;

-- AlterTable
ALTER TABLE "public"."workout_exercises" DROP COLUMN "weight",
ADD COLUMN     "notes" TEXT,
ADD COLUMN     "order" INTEGER,
ADD COLUMN     "restTimeSec" INTEGER,
ADD COLUMN     "targetReps" INTEGER,
ADD COLUMN     "targetSets" INTEGER,
ADD COLUMN     "targetWeight" DOUBLE PRECISION,
ADD COLUMN     "timePerSetSec" INTEGER;
