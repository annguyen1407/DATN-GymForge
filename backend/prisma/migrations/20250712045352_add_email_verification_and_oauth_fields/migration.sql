/*
  Warnings:

  - Added the required column `updatedAt` to the `users` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "users" ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "emailVerificationExpires" TIMESTAMP(3),
ADD COLUMN     "emailVerificationToken" TEXT,
ADD COLUMN     "googleId" TEXT,
ADD COLUMN     "isEmailVerified" BOOLEAN DEFAULT false,
ADD COLUMN     "passwordResetExpires" TIMESTAMP(3),
ADD COLUMN     "passwordResetToken" TEXT,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "workout_plans" ADD COLUMN     "isTemplate" BOOLEAN DEFAULT false;

-- AddForeignKey
ALTER TABLE "workout_exercise_logs" ADD CONSTRAINT "workout_exercise_logs_workoutExerciseId_fkey" FOREIGN KEY ("workoutExerciseId") REFERENCES "workout_exercises"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
