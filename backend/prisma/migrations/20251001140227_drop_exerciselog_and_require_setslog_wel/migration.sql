/*
  Warnings:

  - You are about to drop the column `exerciseLogId` on the `sets_logs` table. All the data in the column will be lost.
  - You are about to drop the `exercise_logs` table. If the table is not empty, all the data it contains will be lost.
  - Made the column `workoutExerciseLogId` on table `sets_logs` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "public"."sets_logs" DROP CONSTRAINT "sets_logs_exerciseLogId_fkey";

-- AlterTable
ALTER TABLE "public"."sets_logs" DROP COLUMN "exerciseLogId",
ALTER COLUMN "workoutExerciseLogId" SET NOT NULL;

-- DropTable
DROP TABLE "public"."exercise_logs";
