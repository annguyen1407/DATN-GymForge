/*
  Warnings:

  - The `goal` column on the `users` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- CreateEnum
CREATE TYPE "FitnessGoal" AS ENUM ('LOSE_WEIGHT', 'BUILD_MUSCLE', 'BULKING', 'CUTTING', 'STRENGTH_TRAINING', 'ENDURANCE', 'GENERAL_FITNESS', 'FLEXIBILITY', 'WEIGHT_MAINTENANCE', 'ATHLETIC_PERFORMANCE');

-- AlterTable
ALTER TABLE "users" DROP COLUMN "goal",
ADD COLUMN     "goal" "FitnessGoal";
