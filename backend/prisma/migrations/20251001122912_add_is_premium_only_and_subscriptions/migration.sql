-- CreateEnum
CREATE TYPE "public"."SubscriptionStatus" AS ENUM ('ACTIVE', 'EXPIRED', 'CANCELED');

-- AlterTable
ALTER TABLE "public"."users" ADD COLUMN     "premiumExpiresAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "public"."workout_plans" ADD COLUMN     "isPremiumOnly" BOOLEAN DEFAULT false;

-- CreateTable
CREATE TABLE "public"."subscription_plans" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "durationMonths" INTEGER NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'VND',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscription_plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."user_subscriptions" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "planId" UUID NOT NULL,
    "startAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endAt" TIMESTAMP(3) NOT NULL,
    "status" "public"."SubscriptionStatus" NOT NULL DEFAULT 'ACTIVE',
    "autoRenew" BOOLEAN DEFAULT false,

    CONSTRAINT "user_subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."subscription_payments" (
    "id" UUID NOT NULL,
    "subscriptionId" UUID NOT NULL,
    "payerUserId" UUID NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "method" "public"."PaymentMethod" NOT NULL,
    "status" "public"."PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "capturedAt" TIMESTAMP(3),
    "refundedAt" TIMESTAMP(3),
    "failureReason" TEXT,

    CONSTRAINT "subscription_payments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "subscription_plans_isActive_idx" ON "public"."subscription_plans"("isActive");

-- CreateIndex
CREATE INDEX "user_subscriptions_userId_idx" ON "public"."user_subscriptions"("userId");

-- CreateIndex
CREATE INDEX "user_subscriptions_status_idx" ON "public"."user_subscriptions"("status");

-- CreateIndex
CREATE INDEX "user_subscriptions_endAt_idx" ON "public"."user_subscriptions"("endAt");

-- CreateIndex
CREATE UNIQUE INDEX "subscription_payments_subscriptionId_key" ON "public"."subscription_payments"("subscriptionId");

-- CreateIndex
CREATE INDEX "subscription_payments_payerUserId_idx" ON "public"."subscription_payments"("payerUserId");

-- CreateIndex
CREATE INDEX "subscription_payments_status_idx" ON "public"."subscription_payments"("status");

-- CreateIndex
CREATE INDEX "users_premiumStatus_idx" ON "public"."users"("premiumStatus");

-- CreateIndex
CREATE INDEX "workout_plans_isPremiumOnly_idx" ON "public"."workout_plans"("isPremiumOnly");

-- AddForeignKey
ALTER TABLE "public"."user_subscriptions" ADD CONSTRAINT "user_subscriptions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."user_subscriptions" ADD CONSTRAINT "user_subscriptions_planId_fkey" FOREIGN KEY ("planId") REFERENCES "public"."subscription_plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."subscription_payments" ADD CONSTRAINT "subscription_payments_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "public"."user_subscriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
