-- DropForeignKey
ALTER TABLE "public"."exercise_muscle_groups" DROP CONSTRAINT "exercise_muscle_groups_exerciseId_fkey";

-- DropForeignKey
ALTER TABLE "public"."exercise_muscle_groups" DROP CONSTRAINT "exercise_muscle_groups_muscleGroupId_fkey";

-- DropForeignKey
ALTER TABLE "public"."messages" DROP CONSTRAINT "messages_conversationId_fkey";

-- DropForeignKey
ALTER TABLE "public"."sets_logs" DROP CONSTRAINT "sets_logs_exerciseLogId_fkey";

-- DropForeignKey
ALTER TABLE "public"."workout_days" DROP CONSTRAINT "workout_days_workoutPlanId_fkey";

-- DropForeignKey
ALTER TABLE "public"."workout_exercise_logs" DROP CONSTRAINT "workout_exercise_logs_logId_fkey";

-- DropForeignKey
ALTER TABLE "public"."workout_exercise_logs" DROP CONSTRAINT "workout_exercise_logs_workoutExerciseId_fkey";

-- DropForeignKey
ALTER TABLE "public"."workout_exercises" DROP CONSTRAINT "workout_exercises_workoutPlanId_fkey";

-- AlterTable
ALTER TABLE "public"."users" ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "isDeleted" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX "achievements_userId_idx" ON "public"."achievements"("userId");

-- CreateIndex
CREATE INDEX "achievements_achievedAt_idx" ON "public"."achievements"("achievedAt");

-- CreateIndex
CREATE INDEX "appointments_gymerId_idx" ON "public"."appointments"("gymerId");

-- CreateIndex
CREATE INDEX "appointments_coachId_idx" ON "public"."appointments"("coachId");

-- CreateIndex
CREATE INDEX "appointments_workoutExerciseId_idx" ON "public"."appointments"("workoutExerciseId");

-- CreateIndex
CREATE INDEX "appointments_date_idx" ON "public"."appointments"("date");

-- CreateIndex
CREATE INDEX "appointments_status_idx" ON "public"."appointments"("status");

-- CreateIndex
CREATE INDEX "conversations_coachId_idx" ON "public"."conversations"("coachId");

-- CreateIndex
CREATE INDEX "conversations_gymerId_idx" ON "public"."conversations"("gymerId");

-- CreateIndex
CREATE INDEX "exercise_muscle_groups_exerciseId_idx" ON "public"."exercise_muscle_groups"("exerciseId");

-- CreateIndex
CREATE INDEX "exercise_muscle_groups_muscleGroupId_idx" ON "public"."exercise_muscle_groups"("muscleGroupId");

-- CreateIndex
CREATE INDEX "exercise_muscle_groups_exerciseId_muscleGroupId_idx" ON "public"."exercise_muscle_groups"("exerciseId", "muscleGroupId");

-- CreateIndex
CREATE INDEX "exercises_userId_idx" ON "public"."exercises"("userId");

-- CreateIndex
CREATE INDEX "exercises_equipmentId_idx" ON "public"."exercises"("equipmentId");

-- CreateIndex
CREATE INDEX "exercises_name_idx" ON "public"."exercises"("name");

-- CreateIndex
CREATE INDEX "feedbacks_gymerId_idx" ON "public"."feedbacks"("gymerId");

-- CreateIndex
CREATE INDEX "feedbacks_coachId_idx" ON "public"."feedbacks"("coachId");

-- CreateIndex
CREATE INDEX "feedbacks_createdAt_idx" ON "public"."feedbacks"("createdAt");

-- CreateIndex
CREATE INDEX "logs_userId_idx" ON "public"."logs"("userId");

-- CreateIndex
CREATE INDEX "logs_dateLogged_idx" ON "public"."logs"("dateLogged");

-- CreateIndex
CREATE INDEX "meals_date_idx" ON "public"."meals"("date");

-- CreateIndex
CREATE INDEX "meals_meal_type_idx" ON "public"."meals"("meal_type");

-- CreateIndex
CREATE INDEX "messages_conversationId_idx" ON "public"."messages"("conversationId");

-- CreateIndex
CREATE INDEX "messages_senderId_idx" ON "public"."messages"("senderId");

-- CreateIndex
CREATE INDEX "messages_createdAt_idx" ON "public"."messages"("createdAt");

-- CreateIndex
CREATE INDEX "notifications_userId_idx" ON "public"."notifications"("userId");

-- CreateIndex
CREATE INDEX "notifications_isRead_idx" ON "public"."notifications"("isRead");

-- CreateIndex
CREATE INDEX "notifications_createdAt_idx" ON "public"."notifications"("createdAt");

-- CreateIndex
CREATE INDEX "payments_userId_idx" ON "public"."payments"("userId");

-- CreateIndex
CREATE INDEX "payments_status_idx" ON "public"."payments"("status");

-- CreateIndex
CREATE INDEX "payments_paymentDate_idx" ON "public"."payments"("paymentDate");

-- CreateIndex
CREATE INDEX "training_requests_gymerId_idx" ON "public"."training_requests"("gymerId");

-- CreateIndex
CREATE INDEX "training_requests_coachId_idx" ON "public"."training_requests"("coachId");

-- CreateIndex
CREATE INDEX "training_requests_status_idx" ON "public"."training_requests"("status");

-- CreateIndex
CREATE INDEX "training_requests_requestedAt_idx" ON "public"."training_requests"("requestedAt");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "public"."users"("email");

-- CreateIndex
CREATE INDEX "users_username_idx" ON "public"."users"("username");

-- CreateIndex
CREATE INDEX "users_isDeleted_idx" ON "public"."users"("isDeleted");

-- CreateIndex
CREATE INDEX "users_role_idx" ON "public"."users"("role");

-- CreateIndex
CREATE INDEX "users_isDeleted_role_idx" ON "public"."users"("isDeleted", "role");

-- CreateIndex
CREATE INDEX "users_createdAt_idx" ON "public"."users"("createdAt");

-- CreateIndex
CREATE INDEX "workout_days_workoutPlanId_idx" ON "public"."workout_days"("workoutPlanId");

-- CreateIndex
CREATE INDEX "workout_days_dayNumber_idx" ON "public"."workout_days"("dayNumber");

-- CreateIndex
CREATE INDEX "workout_exercise_logs_workoutExerciseId_idx" ON "public"."workout_exercise_logs"("workoutExerciseId");

-- CreateIndex
CREATE INDEX "workout_exercise_logs_logId_idx" ON "public"."workout_exercise_logs"("logId");

-- CreateIndex
CREATE INDEX "workout_exercise_logs_date_idx" ON "public"."workout_exercise_logs"("date");

-- CreateIndex
CREATE INDEX "workout_exercises_workoutPlanId_idx" ON "public"."workout_exercises"("workoutPlanId");

-- CreateIndex
CREATE INDEX "workout_exercises_workoutDayId_idx" ON "public"."workout_exercises"("workoutDayId");

-- CreateIndex
CREATE INDEX "workout_exercises_exerciseId_idx" ON "public"."workout_exercises"("exerciseId");

-- CreateIndex
CREATE INDEX "workout_exercises_dayNumber_idx" ON "public"."workout_exercises"("dayNumber");

-- CreateIndex
CREATE INDEX "workout_exercises_workoutDayId_order_idx" ON "public"."workout_exercises"("workoutDayId", "order");

-- CreateIndex
CREATE INDEX "workout_plans_userId_idx" ON "public"."workout_plans"("userId");

-- CreateIndex
CREATE INDEX "workout_plans_isTemplate_idx" ON "public"."workout_plans"("isTemplate");

-- CreateIndex
CREATE INDEX "workout_plans_status_idx" ON "public"."workout_plans"("status");

-- AddForeignKey
ALTER TABLE "public"."messages" ADD CONSTRAINT "messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "public"."conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."workout_days" ADD CONSTRAINT "workout_days_workoutPlanId_fkey" FOREIGN KEY ("workoutPlanId") REFERENCES "public"."workout_plans"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."workout_exercises" ADD CONSTRAINT "workout_exercises_workoutPlanId_fkey" FOREIGN KEY ("workoutPlanId") REFERENCES "public"."workout_plans"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."exercise_muscle_groups" ADD CONSTRAINT "exercise_muscle_groups_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "public"."exercises"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."exercise_muscle_groups" ADD CONSTRAINT "exercise_muscle_groups_muscleGroupId_fkey" FOREIGN KEY ("muscleGroupId") REFERENCES "public"."muscle_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."workout_exercise_logs" ADD CONSTRAINT "workout_exercise_logs_logId_fkey" FOREIGN KEY ("logId") REFERENCES "public"."logs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."workout_exercise_logs" ADD CONSTRAINT "workout_exercise_logs_workoutExerciseId_fkey" FOREIGN KEY ("workoutExerciseId") REFERENCES "public"."workout_exercises"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."sets_logs" ADD CONSTRAINT "sets_logs_exerciseLogId_fkey" FOREIGN KEY ("exerciseLogId") REFERENCES "public"."exercise_logs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
