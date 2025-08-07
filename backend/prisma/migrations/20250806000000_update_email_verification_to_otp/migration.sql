-- AlterTable
ALTER TABLE "users" DROP COLUMN "emailVerificationToken",
DROP COLUMN "emailVerificationExpires",
ADD COLUMN "emailVerificationOTP" VARCHAR(6),
ADD COLUMN "emailVerificationOTPExpires" TIMESTAMP(3);
