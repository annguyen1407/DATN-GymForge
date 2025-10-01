import { Injectable, NotFoundException, ConflictException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TrainingRequest, TrainingRequestStatus, PaymentStatus, PaymentMethod } from '@prisma/client';
import { CreateTrainingRequestDto } from './dto/create-training-request.dto';
import { UpdateTrainingRequestDto } from './dto/update-training-request.dto';

@Injectable()
export class TrainingRequestsService {
  constructor(private prisma: PrismaService) {}

  async create(createTrainingRequestDto: CreateTrainingRequestDto): Promise<TrainingRequest> {
    // Verify gymer and coach exist
    const [gymer, coach] = await Promise.all([
      this.prisma.gymer.findUnique({ where: { id: createTrainingRequestDto.gymerId } }),
      this.prisma.coach.findUnique({ where: { id: createTrainingRequestDto.coachId } }),
    ]);

    if (!gymer) throw new NotFoundException('Gymer not found');
    if (!coach) throw new NotFoundException('Coach not found');

    // Check if there's already a pending request between these users
    const existingRequest = await this.prisma.trainingRequest.findFirst({
      where: {
        gymerId: createTrainingRequestDto.gymerId,
        coachId: createTrainingRequestDto.coachId,
        status: TrainingRequestStatus.PENDING,
      },
    });
    if (existingRequest) {
      throw new ConflictException('A pending training request already exists between these users');
    }

    // Load pricing config
    const config = await this.prisma.adminConfig.findUnique({ where: { id: 'singleton' } });
    if (!config || config.basePriceX == null) {
      throw new ConflictException('Admin pricing configuration (basePriceX) is not set');
    }

    const R = coach.averageRating ?? 0;
    const X = config.basePriceX;
    const alpha = config.ratingMultiplier ?? 0.2;
    let price = X * (1 + alpha * ((R - 3) / 2));
    price = Math.round(price * 100) / 100; // 2 decimals

    const cancelWindowDays = config.coachCancelLockDays ?? 30;
    const trainingDate = (createTrainingRequestDto as any).trainingDate
      ? new Date((createTrainingRequestDto as any).trainingDate)
      : undefined;

    return this.prisma.$transaction(async (tx) => {
      const created = await tx.trainingRequest.create({
        data: {
          gymerId: createTrainingRequestDto.gymerId,
          coachId: createTrainingRequestDto.coachId,
          status: TrainingRequestStatus.PENDING,
          quotedPrice: price,
          trainingDate: trainingDate,
          cancelWindowDays,
        },
      });

      await tx.trainingPayment.create({
        data: {
          trainingRequestId: created.id,
          payerUserId: gymer.userId,
          coachId: coach.id,
          amount: price,
          method: PaymentMethod.APPLE_IAP,
          status: PaymentStatus.PENDING,
        },
      });

      return tx.trainingRequest.findUnique({
        where: { id: created.id },
        include: {
          gymer: {
            include: {
              user: { select: { id: true, name: true, email: true, phoneNumber: true } },
            },
          },
          coach: {
            include: {
              user: { select: { id: true, name: true, email: true, phoneNumber: true } },
            },
          },
          trainingPayment: true,
        },
      }) as any;
    });
  }

  async findAll(gymerId?: string, coachId?: string, status?: TrainingRequestStatus): Promise<TrainingRequest[]> {
    const where: any = {};

    if (gymerId) where.gymerId = gymerId;
    if (coachId) where.coachId = coachId;
    if (status) where.status = status;

    return this.prisma.trainingRequest.findMany({
      where,
      include: {
        gymer: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
              },
            },
          },
        },
        coach: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
              },
            },
          },
        },
      },
      orderBy: {
        requestedAt: 'desc',
      },
    });
  }

  async findOne(id: string): Promise<TrainingRequest> {
    const trainingRequest = await this.prisma.trainingRequest.findUnique({
      where: { id },
      include: {
        gymer: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
              },
            },
          },
        },
        coach: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
              },
            },
          },
        },
      },
    });

    if (!trainingRequest) {
      throw new NotFoundException('Training request not found');
    }

    return trainingRequest;
  }

  async update(id: string, updateTrainingRequestDto: UpdateTrainingRequestDto, currentUserId?: string): Promise<TrainingRequest> {
    const trainingRequest = await this.findOne(id);

    // Check permissions - only gymer, coach, or admin can update
    if (currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
        include: {
          coachProfile: true,
          gymerProfile: true,
        },
      });

      const isOwner = 
        (user?.gymerProfile?.id === trainingRequest.gymerId) ||
        (user?.coachProfile?.id === trainingRequest.coachId) ||
        (user?.role === 'ADMIN');

      if (!isOwner) {
        throw new ForbiddenException('You can only update your own training requests');
      }
    }

    return this.prisma.trainingRequest.update({
      where: { id },
      data: updateTrainingRequestDto,
      include: {
        gymer: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
              },
            },
          },
        },
        coach: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
              },
            },
          },
        },
      },
    });
  }

  async remove(id: string, currentUserId?: string): Promise<TrainingRequest> {
    const trainingRequest = await this.findOne(id);

    // Check permissions - only gymer, coach, or admin can delete
    if (currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
        include: {
          coachProfile: true,
          gymerProfile: true,
        },
      });

      const isOwner = 
        (user?.gymerProfile?.id === trainingRequest.gymerId) ||
        (user?.coachProfile?.id === trainingRequest.coachId) ||
        (user?.role === 'ADMIN');

      if (!isOwner) {
        throw new ForbiddenException('You can only delete your own training requests');
      }
    }

    return this.prisma.trainingRequest.delete({
      where: { id },
    });
  }

  async accept(id: string, currentUserId?: string): Promise<TrainingRequest> {
    const trainingRequest = await this.findOne(id);

    // Only the coach can accept the request
    if (currentUserId) {
      const user = await this.prisma.user.findUnique({ where: { id: currentUserId }, include: { coachProfile: true } });
      if (user?.coachProfile?.id !== trainingRequest.coachId && user?.role !== 'ADMIN') {
        throw new ForbiddenException('Only the coach can accept this training request');
      }
    }

    if (trainingRequest.status !== TrainingRequestStatus.PENDING) {
      throw new ConflictException('Only pending requests can be accepted');
    }

    const config = await this.prisma.adminConfig.findUnique({ where: { id: 'singleton' } });
    const c = config?.commissionRate ?? 0.1;

    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.trainingPayment.findUnique({ where: { trainingRequestId: id } });
      if (!payment) throw new NotFoundException('Training payment not found');

      await tx.trainingPayment.update({
        where: { trainingRequestId: id },
        data: { status: PaymentStatus.COMPLETED, capturedAt: new Date() },
      });

      const commission = Math.round(payment.amount * c * 100) / 100;
      const net = Math.round((payment.amount - commission) * 100) / 100;
      await tx.coachEarning.create({
        data: {
          coachId: trainingRequest.coachId,
          trainingRequestId: id,
          amountGross: payment.amount,
          commission,
          amountNet: net,
        },
      });

      return tx.trainingRequest.update({
        where: { id },
        data: { status: TrainingRequestStatus.ACCEPTED },
        include: {
          gymer: { include: { user: { select: { id: true, name: true, email: true, phoneNumber: true } } } },
          coach: { include: { user: { select: { id: true, name: true, email: true, phoneNumber: true } } } },
          trainingPayment: true,
        },
      });
    });
  }

  async reject(id: string, currentUserId?: string): Promise<TrainingRequest> {
    const trainingRequest = await this.findOne(id);

    // Only the coach can reject the request
    if (currentUserId) {
      const user = await this.prisma.user.findUnique({ where: { id: currentUserId }, include: { coachProfile: true } });
      if (user?.coachProfile?.id !== trainingRequest.coachId && user?.role !== 'ADMIN') {
        throw new ForbiddenException('Only the coach can reject this training request');
      }
    }

    if (trainingRequest.status !== TrainingRequestStatus.PENDING) {
      throw new ConflictException('Only pending requests can be rejected');
    }

    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.trainingPayment.findUnique({ where: { trainingRequestId: id } });
      if (!payment) throw new NotFoundException('Training payment not found');

      await tx.trainingPayment.update({
        where: { trainingRequestId: id },
        data: { status: PaymentStatus.REFUNDED, refundedAt: new Date() },
      });

      return tx.trainingRequest.update({
        where: { id },
        data: { status: TrainingRequestStatus.REJECTED },
        include: {
          gymer: { include: { user: { select: { id: true, name: true, email: true, phoneNumber: true } } } },
          coach: { include: { user: { select: { id: true, name: true, email: true, phoneNumber: true } } } },
          trainingPayment: true,
        },
      });
    });
  }

  async cancel(id: string, currentUserId: string | undefined, reason?: string): Promise<TrainingRequest> {
    const trainingRequest = await this.findOne(id);

    // Only gymer, coach, or admin can cancel
    if (currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
        include: { coachProfile: true, gymerProfile: true },
      });
      const isOwner =
        (user?.gymerProfile?.id === trainingRequest.gymerId) ||
        (user?.coachProfile?.id === trainingRequest.coachId) ||
        (user?.role === 'ADMIN');
      if (!isOwner) {
        throw new ForbiddenException('You can only cancel your own training requests');
      }

      // Anti-scam window for coach cancellations
      if (user?.coachProfile?.id === trainingRequest.coachId && trainingRequest.trainingDate) {
        const days = trainingRequest.cancelWindowDays ?? (await this.prisma.adminConfig.findUnique({ where: { id: 'singleton' } }))?.coachCancelLockDays ?? 30;
        const threshold = new Date(trainingRequest.trainingDate);
        threshold.setDate(threshold.getDate() - days);
        if (new Date() >= threshold) {
          throw new ForbiddenException('Coach cannot cancel within the configured lock window');
        }
      }
    }

    if (trainingRequest.status === TrainingRequestStatus.CANCELED || trainingRequest.status === TrainingRequestStatus.REJECTED) {
      throw new ConflictException('Request is already in a terminal state');
    }

    // No payment mutation on cancel (per current policy)
    return this.prisma.trainingRequest.update({
      where: { id },
      data: {
        status: TrainingRequestStatus.CANCELED,
        canceledAt: new Date(),
        cancelReason: reason ?? undefined,
        canceledByUserId: currentUserId ?? undefined,
      },
      include: {
        gymer: { include: { user: { select: { id: true, name: true, email: true, phoneNumber: true } } } },
        coach: { include: { user: { select: { id: true, name: true, email: true, phoneNumber: true } } } },
        trainingPayment: true,
      },
    });
  }
}
