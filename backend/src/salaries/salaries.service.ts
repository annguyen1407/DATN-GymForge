import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UserRole, SalaryStatus } from '@prisma/client';

@Injectable()
export class SalariesService {
  constructor(private prisma: PrismaService) {}

  private async ensureCoachOrAdmin(requestorId: string, targetCoachId?: string) {
    const user = await this.prisma.user.findUnique({ where: { id: requestorId }, include: { coachProfile: true } });
    if (!user) throw new ForbiddenException('User not found');
    if (user.role === UserRole.ADMIN) return;
    if (!user.coachProfile) throw new ForbiddenException('Only coaches or admins can access salaries');
    if (targetCoachId && targetCoachId !== user.coachProfile.id) throw new ForbiddenException('Cannot access other coach data');
  }

  async listEarningsForCoach(requestorId: string, coachId?: string, year?: number, month?: number) {
    await this.ensureCoachOrAdmin(requestorId, coachId);
    const where: any = { coachId: coachId };
    if (year && month) {
      const start = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0));
      const end = new Date(Date.UTC(month === 12 ? year + 1 : year, month === 12 ? 0 : month, 1, 0, 0, 0));
      where.earnedAt = { gte: start, lt: end };
    }
    return this.prisma.coachEarning.findMany({ where, orderBy: { earnedAt: 'desc' } });
  }

  async getOrComputeMonthlySalary(requestorId: string, coachId?: string, year?: number, month?: number) {
    await this.ensureCoachOrAdmin(requestorId, coachId);

    if (!year || !month) {
      const now = new Date();
      year = now.getUTCFullYear();
      month = now.getUTCMonth() + 1;
    }

    // Aggregate earnings for the month
    const start = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0));
    const end = new Date(Date.UTC(month === 12 ? year + 1 : year, month === 12 ? 0 : month, 1, 0, 0, 0));

    const aggregate = await this.prisma.coachEarning.aggregate({
      _sum: { amountGross: true, commission: true, amountNet: true },
      where: { coachId, earnedAt: { gte: start, lt: end } },
    });

    const totals = {
      totalGross: aggregate._sum.amountGross ?? 0,
      totalCommission: aggregate._sum.commission ?? 0,
      totalNet: aggregate._sum.amountNet ?? 0,
    };

    // Find existing salary and update or create
    const existing = await this.prisma.coachSalary.findFirst({ where: { coachId: coachId!, year, month } });
    if (existing) {
      return this.prisma.coachSalary.update({ where: { id: existing.id }, data: { ...totals } });
    }
    return this.prisma.coachSalary.create({ data: { coachId: coachId!, year, month, status: SalaryStatus.DUE, ...totals } });
  }

  async markPaid(requestorId: string, salaryId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: requestorId } });
    if (!user || user.role !== UserRole.ADMIN) throw new ForbiddenException('Only admin can mark paid');

    return this.prisma.coachSalary.update({
      where: { id: salaryId },
      data: { status: SalaryStatus.PAID, paidAt: new Date(), processedByUserId: requestorId },
    });
  }
}

