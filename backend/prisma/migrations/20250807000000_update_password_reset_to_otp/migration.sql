-- AlterTable
ALTER TABLE "users" DROP COLUMN "passwordResetToken",
DROP COLUMN "passwordResetExpires",
ADD COLUMN "passwordResetOTP" VARCHAR(6),
ADD COLUMN "passwordResetOTPExpires" TIMESTAMP(3);
