import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Coach, User } from '@prisma/client';
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

  async findAll(query?: ListCoachesQueryDto): Promise<Coach[]> {
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

    return this.prisma.coach.findMany({ where, orderBy, include } as any);
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
