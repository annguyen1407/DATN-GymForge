import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Coach, User, Gender, FitnessGoal } from '@prisma/client';
import { CreateCoachDto } from './dto/create-coach.dto';
import { UpdateCoachDto } from './dto/update-coach.dto';
import { EmailService } from '../email/email.service';
import { ListCoachesQueryDto } from './dto/list-coaches.query';

@Injectable()
export class CoachesService {
  constructor(private prisma: PrismaService, private emailService: EmailService) {}

  private computeTrainingPrice(basePriceX: number, ratingMultiplier: number, averageRating: number | null | undefined): number {
    const R = averageRating ?? 0;
    const X = basePriceX;
    const alpha = ratingMultiplier ?? 0.2;
    const price = X * (1 + alpha * ((R - 3) / 2));
    return Math.round(price * 100) / 100; // 2 decimals
  }

  // Simple recommendation score using only available fields
  // Factors considered: goal↔expertise, budget, rating, preferred gender (if provided)
  private computeRecommendationScore(
    coach: Coach & { user?: Partial<User> | null },
    prefs: { budget?: number; preferredGender?: Gender; goal?: FitnessGoal; availableTime?: 'morning' | 'afternoon' | 'evening' },
  ): number {
    type Factor = { v: number; w: number };
    const factors: Factor[] = [];

    // Goal ↔ Coach expertise alignment (~0.30)
    if (prefs?.goal) {
      const exps = (coach as any)?.expertises as FitnessGoal[] | undefined;
      if (Array.isArray(exps)) {
        const v = exps.includes(prefs.goal) ? 1 : 0;
        factors.push({ v, w: 0.3 });
      }
    }

    // Budget match (~0.15)
    if (prefs?.budget !== undefined && coach.trainingPrice !== null && coach.trainingPrice !== undefined) {
      const price = coach.trainingPrice as number;
      const budget = prefs.budget as number;
      let v = 0;
      if (price <= budget) v = 1;
      else if (price <= budget * 1.1) v = 0.7; // within 10%
      else if (price <= budget * 1.25) v = 0.4; // within 25%
      else v = 0.1;
      factors.push({ v, w: 0.15 });
    }

    // Rating normalized 0..1 (~0.30)
    if (coach.averageRating !== null && coach.averageRating !== undefined) {
      const v = Math.max(0, Math.min(1, (coach.averageRating || 0) / 5));
      factors.push({ v, w: 0.3 });
    }

    // Preferred gender match (light ~0.10)
    if (prefs?.preferredGender && coach.user?.sex) {
      const v = coach.user.sex === prefs.preferredGender ? 1 : 0;
      factors.push({ v, w: 0.1 });
    }

    // If no factors available, return 0 so sorting falls back gracefully
    const totalW = factors.reduce((s, f) => s + f.w, 0);
    if (totalW === 0) return 0;
    const score = factors.reduce((s, f) => s + f.v * f.w, 0) / totalW;
    return score;
  }

  async create(createCoachDto: CreateCoachDto): Promise<Coach> {
    // Check if user exists and has COACH role
    const user = await this.prisma.user.findUnique({
      where: { id: createCoachDto.userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.role !== 'COACH') {
      throw new ConflictException('User must have COACH role');
    }

    // Require certification/proof
    if (!createCoachDto.certification || !createCoachDto.certification.trim()) {
      throw new ConflictException('Certification is required for coach registration');
    }

    // Check if coach profile already exists
    const existingCoach = await this.prisma.coach.findUnique({
      where: { userId: createCoachDto.userId },
    });

    if (existingCoach) {
      throw new ConflictException('Coach profile already exists for this user');
    }

    const coach = await this.prisma.coach.create({
      data: { ...createCoachDto, status: 'PENDING' },
      include: {
        user: true,
      },
    });

    // Do NOT grant premium yet; wait for admin approval
    return coach;
  }

  async approve(id: string): Promise<Coach> {
    const coach = await this.prisma.coach.findUnique({ where: { id }, include: { user: true } });
    if (!coach) throw new NotFoundException('Coach not found');

    const updated = await this.prisma.coach.update({
      where: { id },
      data: { status: 'ACTIVE' },
      include: { user: true },
    });

    await this.prisma.user.update({
      where: { id: updated.userId },
      data: { premiumStatus: true, premiumExpiresAt: null },
    });

    // Compute trainingPrice upon activation
    const cfg = await this.prisma.adminConfig.findUnique({ where: { id: 'singleton' } });
    if (cfg) {
      const trainingPrice = this.computeTrainingPrice(cfg.basePriceX, cfg.ratingMultiplier ?? 0.2, updated.averageRating);
      await this.prisma.coach.update({ where: { id }, data: { trainingPrice } as any });
    }

    // Notify coach via email about approval (best-effort)
    try {
      if (updated.user?.email) {
        await this.emailService.sendCoachApprovedNotification(updated.user.email, updated.user.name || 'Coach');
      }
    } catch (e) {
      // ignore mail errors
    }

    return updated;
  }

  async findAll(query?: ListCoachesQueryDto, currentUserId?: string): Promise<Coach[]> {
    const where: any = {};
    if (query?.isOpenToTraining !== undefined) {
      where.isOpenToTraining = query.isOpenToTraining;
    }
    if (query?.minPrice !== undefined || query?.maxPrice !== undefined) {
      where.trainingPrice = {} as any;
      if (query?.minPrice !== undefined) (where.trainingPrice as any).gte = query.minPrice;
      if (query?.maxPrice !== undefined) (where.trainingPrice as any).lte = query.maxPrice;
    }

    const orderBy: any[] = [];
    const sortOrder = (query?.sortOrder ?? 'asc') as 'asc' | 'desc';
    switch (query?.sortBy) {
      case 'price':
        orderBy.push({ trainingPrice: sortOrder });
        break;
      case 'rating':
        orderBy.push({ averageRating: sortOrder });
        break;
      case 'name':
        orderBy.push({ user: { name: sortOrder } });
        break;
      default:
        // default sort by name asc for deterministic order
        orderBy.push({ user: { name: 'asc' } });
    }

    const include = {
      user: {
        select: {
          id: true,
          name: true,
          email: true,
          phoneNumber: true,
          profilePicture: true,
          biography: true,
        },
      },
      _count: {
        select: {
          appointments: true,
          feedbacks: true,
          trainingRequestsSent: true,
        },
      },
    };

    const raw = await this.prisma.coach.findMany({ where, orderBy, include } as any);

    const wantsRecommended = query?.sortBy === 'recommended' || !query?.sortBy;

    if (wantsRecommended) {
      // Pull current user's stored preferences (whatever exists). Avoid strict selects to keep TS happy pre-migration.
      const userPrefs = currentUserId
        ? (await this.prisma.user.findUnique({ where: { id: currentUserId } }))
        : null;

      const prefs = {
        goal: (userPrefs as any)?.goal,
        preferredGender: (userPrefs as any)?.preferredCoachGender,
        budget: (userPrefs as any)?.trainingBudget,
        availableTime: (userPrefs as any)?.availableTime,
      } as any;

      // If preferredGender is set, fetch coach user sexes in bulk (keep original include stable for tests)
      let coachSexByUserId: Record<string, any> | null = null;
      if (prefs?.preferredGender) {
        const coachUserIds = (raw as any[]).map((c) => c.user?.id).filter((id) => !!id);
        if (coachUserIds.length) {
          const rows = await this.prisma.user.findMany({ where: { id: { in: coachUserIds } }, select: { id: true, sex: true } });
          coachSexByUserId = Object.fromEntries(rows.map((r) => [r.id, r.sex]));
        }
      }

      const withScore = (raw as any[]).map((c) => {
        const sex = coachSexByUserId && c.user?.id ? coachSexByUserId[c.user.id] : undefined;
        const coachWithSex = sex !== undefined ? { ...c, user: { ...(c.user || {}), sex } } : c;
        return { ...coachWithSex, _score: this.computeRecommendationScore(coachWithSex as any, prefs) };
      });

      withScore.sort(
        (a, b) => (b._score - a._score) || ((b.averageRating ?? 0) - (a.averageRating ?? 0)) || ((b._count?.feedbacks ?? 0) - (a._count?.feedbacks ?? 0)),
      );
      return withScore.map(({ _score, ...rest }) => rest);
    }

    return raw as any;
  }

  async findOne(id: string): Promise<Coach> {
    const coach = await this.prisma.coach.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phoneNumber: true,
            profilePicture: true,
            biography: true,
          },
        },
        appointments: {
          include: {
            gymer: {
              include: {
                user: {
                  select: {
                    name: true,
                    email: true,
                  },
                },
              },
            },
          },
        },
        feedbacks: {
          include: {
            gymer: {
              include: {
                user: {
                  select: {
                    name: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!coach) {
      throw new NotFoundException('Coach not found');
    }

    return coach;
  }

  async findByUserId(userId: string): Promise<Coach | null> {
    return this.prisma.coach.findUnique({
      where: { userId },
      include: {
        user: true,
      },
    });
  }


  async update(id: string, updateCoachDto: UpdateCoachDto): Promise<Coach> {
    // ensure exists
    await this.findOne(id);
    return this.prisma.coach.update({
      where: { id },
      data: updateCoachDto,
      include: { user: true },
    });
  }

  async updateOpenToTraining(currentUserId: string, isOpenToTraining: boolean): Promise<Coach> {
    const coach = await this.prisma.coach.findUnique({ where: { userId: currentUserId }, include: { user: true } });
    if (!coach) throw new NotFoundException('Coach not found');
    return this.prisma.coach.update({
      where: { id: coach.id },
      data: { isOpenToTraining } as any,
      include: { user: true },
    });
  }

  async remove(id: string): Promise<Coach> {
    // ensure exists
    await this.findOne(id);
    return this.prisma.coach.delete({ where: { id } });
  }

  async updateRating(coachId: string): Promise<void> {
    const feedbacks = await this.prisma.feedback.findMany({
      where: { coachId },
      select: { rating: true },
    });

    if (feedbacks.length > 0) {
      const totalRating = feedbacks.reduce((sum, feedback) => sum + (feedback.rating || 0), 0);
      const averageRating = totalRating / feedbacks.length;

      const updated = await this.prisma.coach.update({
        where: { id: coachId },
        data: {
          averageRating,
          feedbackCount: feedbacks.length,
        },
      });
      // If coach is active, recompute trainingPrice
      if (updated.status === 'ACTIVE') {
        const cfg = await this.prisma.adminConfig.findUnique({ where: { id: 'singleton' } });
        if (cfg) {
          const trainingPrice = this.computeTrainingPrice(cfg.basePriceX, cfg.ratingMultiplier ?? 0.2, updated.averageRating);
          await this.prisma.coach.update({ where: { id: coachId }, data: { trainingPrice } as any });
        }
      }
    }
  }
}
