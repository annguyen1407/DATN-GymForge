/*
  Warnings:

  - You are about to drop the `Achievement` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Appointment` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Coach` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Conversation` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Equipment` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Exercise` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `ExerciseLog` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `ExerciseMuscleGroup` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Feedback` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Gymer` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Log` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Meal` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Message` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `MuscleGroup` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Notification` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Payment` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `SetsLog` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `TrainingRequest` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `User` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `WorkoutExercise` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `WorkoutExerciseLog` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `WorkoutPlan` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "Achievement" DROP CONSTRAINT "Achievement_userId_fkey";

-- DropForeignKey
ALTER TABLE "Appointment" DROP CONSTRAINT "Appointment_coachId_fkey";

-- DropForeignKey
ALTER TABLE "Appointment" DROP CONSTRAINT "Appointment_gymerId_fkey";

-- DropForeignKey
ALTER TABLE "Appointment" DROP CONSTRAINT "Appointment_workoutExerciseId_fkey";

-- DropForeignKey
ALTER TABLE "Coach" DROP CONSTRAINT "Coach_userId_fkey";

-- DropForeignKey
ALTER TABLE "Conversation" DROP CONSTRAINT "Conversation_coachId_fkey";

-- DropForeignKey
ALTER TABLE "Conversation" DROP CONSTRAINT "Conversation_gymerId_fkey";

-- DropForeignKey
ALTER TABLE "Exercise" DROP CONSTRAINT "Exercise_userId_fkey";

-- DropForeignKey
ALTER TABLE "ExerciseMuscleGroup" DROP CONSTRAINT "ExerciseMuscleGroup_exerciseId_fkey";

-- DropForeignKey
ALTER TABLE "ExerciseMuscleGroup" DROP CONSTRAINT "ExerciseMuscleGroup_muscleGroupId_fkey";

-- DropForeignKey
ALTER TABLE "Feedback" DROP CONSTRAINT "Feedback_coachId_fkey";

-- DropForeignKey
ALTER TABLE "Feedback" DROP CONSTRAINT "Feedback_gymerId_fkey";

-- DropForeignKey
ALTER TABLE "Gymer" DROP CONSTRAINT "Gymer_userId_fkey";

-- DropForeignKey
ALTER TABLE "Log" DROP CONSTRAINT "Log_userId_fkey";

-- DropForeignKey
ALTER TABLE "Message" DROP CONSTRAINT "Message_conversationId_fkey";

-- DropForeignKey
ALTER TABLE "Message" DROP CONSTRAINT "Message_senderId_fkey";

-- DropForeignKey
ALTER TABLE "Notification" DROP CONSTRAINT "Notification_userId_fkey";

-- DropForeignKey
ALTER TABLE "Payment" DROP CONSTRAINT "Payment_userId_fkey";

-- DropForeignKey
ALTER TABLE "SetsLog" DROP CONSTRAINT "SetsLog_exerciseLogId_fkey";

-- DropForeignKey
ALTER TABLE "TrainingRequest" DROP CONSTRAINT "TrainingRequest_coachId_fkey";

-- DropForeignKey
ALTER TABLE "TrainingRequest" DROP CONSTRAINT "TrainingRequest_gymerId_fkey";

-- DropForeignKey
ALTER TABLE "WorkoutExercise" DROP CONSTRAINT "WorkoutExercise_workoutPlanId_fkey";

-- DropForeignKey
ALTER TABLE "WorkoutExerciseLog" DROP CONSTRAINT "WorkoutExerciseLog_logId_fkey";

-- DropForeignKey
ALTER TABLE "WorkoutPlan" DROP CONSTRAINT "WorkoutPlan_userId_fkey";

-- DropTable
DROP TABLE "Achievement";

-- DropTable
DROP TABLE "Appointment";

-- DropTable
DROP TABLE "Coach";

-- DropTable
DROP TABLE "Conversation";

-- DropTable
DROP TABLE "Equipment";

-- DropTable
DROP TABLE "Exercise";

-- DropTable
DROP TABLE "ExerciseLog";

-- DropTable
DROP TABLE "ExerciseMuscleGroup";

-- DropTable
DROP TABLE "Feedback";

-- DropTable
DROP TABLE "Gymer";

-- DropTable
DROP TABLE "Log";

-- DropTable
DROP TABLE "Meal";

-- DropTable
DROP TABLE "Message";

-- DropTable
DROP TABLE "MuscleGroup";

-- DropTable
DROP TABLE "Notification";

-- DropTable
DROP TABLE "Payment";

-- DropTable
DROP TABLE "SetsLog";

-- DropTable
DROP TABLE "TrainingRequest";

-- DropTable
DROP TABLE "User";

-- DropTable
DROP TABLE "WorkoutExercise";

-- DropTable
DROP TABLE "WorkoutExerciseLog";

-- DropTable
DROP TABLE "WorkoutPlan";

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "name" TEXT,
    "email" TEXT,
    "username" TEXT,
    "password" TEXT,
    "profilePicture" TEXT,
    "dateOfBirth" DATE,
    "address" TEXT,
    "role" "UserRole",
    "phoneNumber" TEXT,
    "premiumStatus" BOOLEAN DEFAULT false,
    "weight" DOUBLE PRECISION,
    "height" DOUBLE PRECISION,
    "biography" TEXT,
    "goal" TEXT,
    "1RM" DOUBLE PRECISION,
    "expType" TEXT,
    "sex" "Gender",

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "coaches" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "certification" TEXT,
    "status" TEXT,
    "averageRating" DOUBLE PRECISION DEFAULT 0,
    "feedbackCount" INTEGER DEFAULT 0,

    CONSTRAINT "coaches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gymers" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,

    CONSTRAINT "gymers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "training_requests" (
    "id" UUID NOT NULL,
    "gymerId" UUID NOT NULL,
    "coachId" UUID NOT NULL,
    "status" "TrainingRequestStatus" DEFAULT 'PENDING',
    "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "training_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "feedbacks" (
    "id" UUID NOT NULL,
    "gymerId" UUID NOT NULL,
    "coachId" UUID NOT NULL,
    "rating" DOUBLE PRECISION,
    "content" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "feedbacks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversations" (
    "id" UUID NOT NULL,
    "coachId" UUID NOT NULL,
    "gymerId" UUID NOT NULL,

    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" UUID NOT NULL,
    "conversationId" UUID NOT NULL,
    "senderId" UUID NOT NULL,
    "content" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appointments" (
    "id" UUID NOT NULL,
    "gymerId" UUID NOT NULL,
    "coachId" UUID NOT NULL,
    "date" TIMESTAMP(3),
    "workoutExerciseId" UUID,
    "note" TEXT,
    "status" "AppointmentStatus" DEFAULT 'PENDING',
    "location" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "appointments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "message" TEXT,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "amount" DOUBLE PRECISION,
    "method" "PaymentMethod",
    "status" "PaymentStatus" DEFAULT 'PENDING',
    "paymentDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "achievements" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "description" TEXT,
    "achievedAt" DATE,
    "type" TEXT,

    CONSTRAINT "achievements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workout_plans" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "name" TEXT,
    "description" TEXT,
    "workout_plan_picture" TEXT,
    "planType" "PlanType",
    "status" "PlanStatus" DEFAULT 'ACTIVE',
    "days" INTEGER,

    CONSTRAINT "workout_plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workout_exercises" (
    "id" UUID NOT NULL,
    "workoutPlanId" UUID NOT NULL,
    "exerciseId" UUID,
    "dayNumber" INTEGER,
    "weight" DOUBLE PRECISION,

    CONSTRAINT "workout_exercises_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exercises" (
    "id" UUID NOT NULL,
    "userId" UUID,
    "name" TEXT,
    "equipmentId" UUID,
    "description" TEXT,
    "instruction" TEXT,
    "videoUrl" TEXT,
    "met" DOUBLE PRECISION,
    "weight" DOUBLE PRECISION,
    "sets" INTEGER,
    "reps_per_set" INTEGER,
    "time_rest" INTEGER,

    CONSTRAINT "exercises_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "muscle_groups" (
    "id" UUID NOT NULL,
    "name" TEXT,

    CONSTRAINT "muscle_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exercise_muscle_groups" (
    "id" UUID NOT NULL,
    "exerciseId" UUID NOT NULL,
    "muscleGroupId" UUID NOT NULL,

    CONSTRAINT "exercise_muscle_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "equipment" (
    "id" UUID NOT NULL,
    "name" TEXT,
    "equipment_picture" TEXT,

    CONSTRAINT "equipment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "logs" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "dateLogged" DATE,
    "weight" DOUBLE PRECISION,
    "height" DOUBLE PRECISION,
    "calo_burned" DOUBLE PRECISION,
    "calo_input" DOUBLE PRECISION,
    "notes" TEXT,
    "mealId" UUID,

    CONSTRAINT "logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "meals" (
    "id" UUID NOT NULL,
    "date" DATE,
    "calo_input" DOUBLE PRECISION,
    "meal_type" "MealType",
    "name" TEXT,

    CONSTRAINT "meals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workout_exercise_logs" (
    "id" UUID NOT NULL,
    "logId" UUID NOT NULL,
    "workoutExerciseId" UUID NOT NULL,
    "date" DATE,
    "progressPercent" DOUBLE PRECISION,
    "calo_burned" DOUBLE PRECISION,
    "dayNumber" INTEGER,

    CONSTRAINT "workout_exercise_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exercise_logs" (
    "id" UUID NOT NULL,
    "workoutLogId" UUID NOT NULL,

    CONSTRAINT "exercise_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sets_logs" (
    "id" UUID NOT NULL,
    "exerciseLogId" UUID NOT NULL,
    "setNumber" INTEGER,
    "reps" INTEGER,
    "times" INTEGER,
    "weight" DOUBLE PRECISION,
    "calo_burned" DOUBLE PRECISION,

    CONSTRAINT "sets_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");

-- CreateIndex
CREATE UNIQUE INDEX "coaches_userId_key" ON "coaches"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "gymers_userId_key" ON "gymers"("userId");

-- AddForeignKey
ALTER TABLE "coaches" ADD CONSTRAINT "coaches_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gymers" ADD CONSTRAINT "gymers_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "training_requests" ADD CONSTRAINT "training_requests_coachId_fkey" FOREIGN KEY ("coachId") REFERENCES "coaches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "training_requests" ADD CONSTRAINT "training_requests_gymerId_fkey" FOREIGN KEY ("gymerId") REFERENCES "gymers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "feedbacks" ADD CONSTRAINT "feedbacks_coachId_fkey" FOREIGN KEY ("coachId") REFERENCES "coaches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "feedbacks" ADD CONSTRAINT "feedbacks_gymerId_fkey" FOREIGN KEY ("gymerId") REFERENCES "gymers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_coachId_fkey" FOREIGN KEY ("coachId") REFERENCES "coaches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_gymerId_fkey" FOREIGN KEY ("gymerId") REFERENCES "gymers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_gymerId_fkey" FOREIGN KEY ("gymerId") REFERENCES "gymers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_coachId_fkey" FOREIGN KEY ("coachId") REFERENCES "coaches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_workoutExerciseId_fkey" FOREIGN KEY ("workoutExerciseId") REFERENCES "workout_exercises"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "achievements" ADD CONSTRAINT "achievements_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_plans" ADD CONSTRAINT "workout_plans_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_exercises" ADD CONSTRAINT "workout_exercises_workoutPlanId_fkey" FOREIGN KEY ("workoutPlanId") REFERENCES "workout_plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exercises" ADD CONSTRAINT "exercises_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exercise_muscle_groups" ADD CONSTRAINT "exercise_muscle_groups_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "exercises"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exercise_muscle_groups" ADD CONSTRAINT "exercise_muscle_groups_muscleGroupId_fkey" FOREIGN KEY ("muscleGroupId") REFERENCES "muscle_groups"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "logs" ADD CONSTRAINT "logs_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_exercise_logs" ADD CONSTRAINT "workout_exercise_logs_logId_fkey" FOREIGN KEY ("logId") REFERENCES "logs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sets_logs" ADD CONSTRAINT "sets_logs_exerciseLogId_fkey" FOREIGN KEY ("exerciseLogId") REFERENCES "exercise_logs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
