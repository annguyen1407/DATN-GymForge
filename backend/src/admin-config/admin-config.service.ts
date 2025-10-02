import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminConfigService {
  constructor(private prisma: PrismaService) {}

  async get() {
    let cfg = await this.prisma.adminConfig.findUnique({ where: { id: 'singleton' } });
    if (!cfg) {
      cfg = await this.prisma.adminConfig.create({
        data: {
          id: 'singleton',
          basePriceX: 10,
          ratingMultiplier: 0.2,
          commissionRate: 0.1,
          coachCancelLockDays: 30,
        },
      });
    }
    return cfg;
  }

  async update(body: Partial<{ basePriceX: number; ratingMultiplier: number; commissionRate: number; coachCancelLockDays: number }>) {
    if (body.basePriceX != null && body.basePriceX < 0) throw new BadRequestException('basePriceX must be >= 0');
    if (body.ratingMultiplier != null && (body.ratingMultiplier < 0 || body.ratingMultiplier > 1)) throw new BadRequestException('ratingMultiplier must be between 0 and 1');
    if (body.commissionRate != null && (body.commissionRate < 0 || body.commissionRate > 1)) throw new BadRequestException('commissionRate must be between 0 and 1');
    if (body.coachCancelLockDays != null && body.coachCancelLockDays < 0) throw new BadRequestException('coachCancelLockDays must be >= 0');

    const before = await this.get();
    const updated = await this.prisma.adminConfig.update({ where: { id: 'singleton' }, data: body });

    // If pricing knobs changed, recompute trainingPrice for ACTIVE coaches
    const priceKnobsChanged = (
      (body.basePriceX != null && body.basePriceX !== before.basePriceX) ||
      (body.ratingMultiplier != null && body.ratingMultiplier !== before.ratingMultiplier)
    );

    if (priceKnobsChanged) {
      const coaches = await this.prisma.coach.findMany({ where: { status: 'ACTIVE' } });
      for (const c of coaches) {
        const R = c.averageRating ?? 0;
        const X = updated.basePriceX;
        const alpha = updated.ratingMultiplier ?? 0.2;
        const price = Math.round((X * (1 + alpha * ((R - 3) / 2))) * 100) / 100;
        await this.prisma.coach.update({ where: { id: c.id }, data: { trainingPrice: price } as any });
      }
    }

    return updated;
  }
}

