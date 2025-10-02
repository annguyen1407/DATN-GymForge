-- AlterTable
ALTER TABLE "public"."coaches" ADD COLUMN     "isOpenToTraining" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "trainingPrice" DOUBLE PRECISION;
