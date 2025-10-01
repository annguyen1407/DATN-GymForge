import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentMethod, PaymentStatus, SubscriptionPlan, SubscriptionStatus, User } from '@prisma/client';
import { addMonths } from './utils/date';

@Injectable()
export class SubscriptionsService {
  constructor(private prisma: PrismaService) {}

  async listPlans(): Promise<SubscriptionPlan[]> {
    return this.prisma.subscriptionPlan.findMany({ where: { isActive: true }, orderBy: { durationMonths: 'asc' } });
  }

  async createPlan(data: {
    name: string;
    durationMonths: number;
    price: number;
    currency?: string;
    isActive?: boolean;
  }): Promise<SubscriptionPlan> {
    return this.prisma.subscriptionPlan.create({ data });
  }

  async updatePlan(id: string, data: Partial<SubscriptionPlan>): Promise<SubscriptionPlan> {
    const plan = await this.prisma.subscriptionPlan.findUnique({ where: { id } });
    if (!plan) throw new NotFoundException('Subscription plan not found');
    return this.prisma.subscriptionPlan.update({ where: { id }, data });
  }

  async getStatus(userId: string): Promise<{ isPremium: boolean; expiresAt: Date | null }> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const isCoach = user.role === 'COACH';

    // If coach, treat as premium regardless of expiresAt
    if (isCoach) {
      return { isPremium: true, expiresAt: null };
    }

    // If user has a premiumExpiresAt in the future, they are premium
    if (user.premiumExpiresAt && user.premiumExpiresAt > new Date()) {
      return { isPremium: true, expiresAt: user.premiumExpiresAt };
    }

    // Fallback: look up active subscription rows
    const active = await this.prisma.userSubscription.findFirst({
      where: { userId, status: 'ACTIVE', endAt: { gt: new Date() } },
      orderBy: { endAt: 'desc' },
    });

    return { isPremium: !!active, expiresAt: active?.endAt ?? null };
  }

  async isUserPremium(userId: string): Promise<boolean> {
    const status = await this.getStatus(userId);
    return status.isPremium;
  }

  async purchase(userId: string, planId: string, method: PaymentMethod, providerToken?: string) {
    const [user, plan] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId } }),
      this.prisma.subscriptionPlan.findUnique({ where: { id: planId } }),
    ]);

    if (!user) throw new NotFoundException('User not found');
    if (!plan || !plan.isActive) throw new NotFoundException('Subscription plan not found or inactive');

    // Determine start time: extend from current expiry if active
    const now = new Date();
    let startAt = now;
    const existing = await this.prisma.userSubscription.findFirst({
      where: { userId, status: 'ACTIVE' },
      orderBy: { endAt: 'desc' },
    });

    if (existing && existing.endAt > now) {
      startAt = existing.endAt;
    }

    const endAt = addMonths(startAt, plan.durationMonths);

    const subscription = await this.prisma.userSubscription.create({
      data: {
        userId,
        planId,
        startAt,
        endAt,
        status: 'ACTIVE',
      },
    });

    // Create a payment record (mock integration for now)
    await this.prisma.subscriptionPayment.create({
      data: {
        subscriptionId: subscription.id,
        payerUserId: userId,
        amount: plan.price,
        method,
        status: 'COMPLETED',
        capturedAt: new Date(),
        failureReason: null,
      },
    });

    // Update user cached premium fields
    await this.prisma.user.update({
      where: { id: userId },
      data: { premiumStatus: true, premiumExpiresAt: endAt },
    });

    return subscription;
  }

  async grantCoachPremium(user: User): Promise<void> {
    // Set premium flags; coach premium has no expiry in this implementation
    await this.prisma.user.update({
      where: { id: user.id },
      data: { premiumStatus: true, premiumExpiresAt: null },
    });
  }
}

