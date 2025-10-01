-- CreateEnum
CREATE TYPE "public"."SalaryStatus" AS ENUM ('DUE', 'PAID');

-- AlterEnum
ALTER TYPE "public"."PaymentMethod" ADD VALUE 'APPLE_IAP';

-- AlterTable
ALTER TABLE "public"."training_requests" ADD COLUMN     "cancelReason" TEXT,
ADD COLUMN     "cancelWindowDays" INTEGER DEFAULT 30,
ADD COLUMN     "canceledAt" TIMESTAMP(3),
ADD COLUMN     "canceledByUserId" UUID,
ADD COLUMN     "quotedPrice" DOUBLE PRECISION,
ADD COLUMN     "trainingDate" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "public"."workout_plans" ADD COLUMN     "createdByCoachId" UUID,
ADD COLUMN     "trainingRequestId" UUID;

-- CreateTable
CREATE TABLE "public"."training_payments" (
    "id" UUID NOT NULL,
    "trainingRequestId" UUID NOT NULL,
    "payerUserId" UUID NOT NULL,
    "coachId" UUID NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "method" "public"."PaymentMethod" NOT NULL,
    "status" "public"."PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "capturedAt" TIMESTAMP(3),
    "refundedAt" TIMESTAMP(3),
    "failureReason" TEXT,

    CONSTRAINT "training_payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."coach_earnings" (
    "id" UUID NOT NULL,
    "coachId" UUID NOT NULL,
    "trainingRequestId" UUID NOT NULL,
    "amountGross" DOUBLE PRECISION NOT NULL,
    "commission" DOUBLE PRECISION NOT NULL,
    "amountNet" DOUBLE PRECISION NOT NULL,
    "earnedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "salaryId" UUID,

    CONSTRAINT "coach_earnings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."coach_salaries" (
    "id" UUID NOT NULL,
    "coachId" UUID NOT NULL,
    "year" INTEGER NOT NULL,
    "month" INTEGER NOT NULL,
    "totalGross" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalCommission" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalNet" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "status" "public"."SalaryStatus" NOT NULL DEFAULT 'DUE',
    "paidAt" TIMESTAMP(3),
    "processedByUserId" UUID,

    CONSTRAINT "coach_salaries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."admin_config" (
    "id" TEXT NOT NULL DEFAULT 'singleton',
    "basePriceX" DOUBLE PRECISION NOT NULL,
    "ratingMultiplier" DOUBLE PRECISION NOT NULL DEFAULT 0.2,
    "commissionRate" DOUBLE PRECISION NOT NULL DEFAULT 0.1,
    "coachCancelLockDays" INTEGER NOT NULL DEFAULT 30,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "admin_config_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "training_payments_trainingRequestId_key" ON "public"."training_payments"("trainingRequestId");

-- CreateIndex
CREATE INDEX "training_payments_coachId_idx" ON "public"."training_payments"("coachId");

-- CreateIndex
CREATE INDEX "training_payments_status_idx" ON "public"."training_payments"("status");

-- CreateIndex
CREATE UNIQUE INDEX "coach_earnings_trainingRequestId_key" ON "public"."coach_earnings"("trainingRequestId");

-- CreateIndex
CREATE INDEX "coach_earnings_coachId_idx" ON "public"."coach_earnings"("coachId");

-- CreateIndex
CREATE INDEX "coach_earnings_earnedAt_idx" ON "public"."coach_earnings"("earnedAt");

-- CreateIndex
CREATE INDEX "coach_salaries_coachId_idx" ON "public"."coach_salaries"("coachId");

-- CreateIndex
CREATE INDEX "coach_salaries_year_month_idx" ON "public"."coach_salaries"("year", "month");

-- CreateIndex
CREATE INDEX "coach_salaries_status_idx" ON "public"."coach_salaries"("status");

-- CreateIndex
CREATE INDEX "workout_plans_createdByCoachId_idx" ON "public"."workout_plans"("createdByCoachId");

-- CreateIndex
CREATE INDEX "workout_plans_trainingRequestId_idx" ON "public"."workout_plans"("trainingRequestId");

-- AddForeignKey
ALTER TABLE "public"."workout_plans" ADD CONSTRAINT "workout_plans_createdByCoachId_fkey" FOREIGN KEY ("createdByCoachId") REFERENCES "public"."coaches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."workout_plans" ADD CONSTRAINT "workout_plans_trainingRequestId_fkey" FOREIGN KEY ("trainingRequestId") REFERENCES "public"."training_requests"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."training_payments" ADD CONSTRAINT "training_payments_trainingRequestId_fkey" FOREIGN KEY ("trainingRequestId") REFERENCES "public"."training_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."coach_earnings" ADD CONSTRAINT "coach_earnings_salaryId_fkey" FOREIGN KEY ("salaryId") REFERENCES "public"."coach_salaries"("id") ON DELETE SET NULL ON UPDATE CASCADE;
