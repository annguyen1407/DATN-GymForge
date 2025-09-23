/*
  Warnings:

  - You are about to drop the column `mealId` on the `logs` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "public"."logs" DROP COLUMN "mealId";

-- AlterTable
ALTER TABLE "public"."meals" ADD COLUMN     "logId" UUID;

-- CreateIndex
CREATE INDEX "meals_logId_idx" ON "public"."meals"("logId");

-- AddForeignKey
ALTER TABLE "public"."meals" ADD CONSTRAINT "meals_logId_fkey" FOREIGN KEY ("logId") REFERENCES "public"."logs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
