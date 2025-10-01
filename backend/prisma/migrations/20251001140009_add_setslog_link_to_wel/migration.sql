-- AlterTable
ALTER TABLE "public"."sets_logs" ADD COLUMN     "workoutExerciseLogId" UUID;

-- CreateIndex
CREATE INDEX "sets_logs_workoutExerciseLogId_idx" ON "public"."sets_logs"("workoutExerciseLogId");

-- AddForeignKey
ALTER TABLE "public"."sets_logs" ADD CONSTRAINT "sets_logs_workoutExerciseLogId_fkey" FOREIGN KEY ("workoutExerciseLogId") REFERENCES "public"."workout_exercise_logs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
