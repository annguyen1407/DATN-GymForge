-- CreateEnum
CREATE TYPE "public"."AvailableTime" AS ENUM ('MORNING', 'AFTERNOON', 'EVENING');

-- AlterTable
ALTER TABLE "public"."coaches" ADD COLUMN     "expertises" "public"."FitnessGoal"[];

-- AlterTable
ALTER TABLE "public"."users" ADD COLUMN     "availableTime" "public"."AvailableTime",
ADD COLUMN     "preferredCoachGender" "public"."Gender",
ADD COLUMN     "trainingBudget" DOUBLE PRECISION;
