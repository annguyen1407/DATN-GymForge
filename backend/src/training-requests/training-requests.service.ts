import { Injectable, NotFoundException, ConflictException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TrainingRequest, TrainingRequestStatus, PaymentStatus, PaymentMethod } from '@prisma/client';
import { CreateTrainingRequestDto } from './dto/create-training-request.dto';
import { UpdateTrainingRequestDto } from './dto/update-training-request.dto';

@Injectable()
export class TrainingRequestsService {
  constructor(private prisma: PrismaService) {}

  async create(createTrainingRequestDto: CreateTrainingRequestDto): Promise<TrainingRequest> {
    // Resolve gymer and coach by id or userId
    const gymer = createTrainingRequestDto.gymerId
      ? await this.prisma.gymer.findUnique({ where: { id: createTrainingRequestDto.gymerId } })
      : (createTrainingRequestDto.gymerUserId
        ? await this.prisma.gymer.findUnique({ where: { userId: createTrainingRequestDto.gymerUserId } })
        : null);

    const coach: any = createTrainingRequestDto.coachId
      ? await this.prisma.coach.findUnique({ where: { id: createTrainingRequestDto.coachId } })
      : (createTrainingRequestDto.coachUserId
        ? await this.prisma.coach.findUnique({ where: { userId: createTrainingRequestDto.coachUserId } })
        : null);

    if (!gymer) throw new NotFoundException('Gymer not found');
    if (!coach) throw new NotFoundException('Coach not found');

    // Coach must be ACTIVE and open to training
    if (coach.status !== 'ACTIVE') {
      throw new ConflictException('Coach is not active/approved');
    }
    if (!coach.isOpenToTraining) {
      throw new ConflictException('Coach is not open to training');
    }

    // Prevent duplicate active training
    const existingAccepted = await this.prisma.trainingRequest.findFirst({
      where: {
        gymerId: gymer.id,
        coachId: coach.id,
        status: TrainingRequestStatus.ACCEPTED,
      },
    });
    if (existingAccepted) {
      throw new ConflictException('An active training already exists between these users');
    }

    // Load pricing config
    const config = await this.prisma.adminConfig.findUnique({ where: { id: 'singleton' } });
    if (!config || config.basePriceX == null) {
      throw new ConflictException('Admin pricing configuration (basePriceX) is not set');
    }

    // Use cached price if present, otherwise compute
    let price = coach.trainingPrice ?? 0;
    if (!price) {
      const R = coach.averageRating ?? 0;
      const X = config.basePriceX;
      const alpha = config.ratingMultiplier ?? 0.2;
      price = Math.round((X * (1 + alpha * ((R - 3) / 2))) * 100) / 100;
    }

    const cancelWindowDays = config.coachCancelLockDays ?? 30;
    const trainingDate = (createTrainingRequestDto as any).trainingDate
      ? new Date((createTrainingRequestDto as any).trainingDate)
      : undefined;

    const commissionRate = config.commissionRate ?? 0.1;

    return this.prisma.$transaction(async (tx) => {
      const created = await tx.trainingRequest.create({
        data: {
          gymerId: gymer.id,
          coachId: coach.id,
          status: TrainingRequestStatus.ACCEPTED,
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
          status: PaymentStatus.COMPLETED,
          capturedAt: new Date(),
        },
      });

      const commission = Math.round(price * commissionRate * 100) / 100;
      const net = Math.round((price - commission) * 100) / 100;
      await tx.coachEarning.create({
        data: {
          coachId: coach.id,
          trainingRequestId: created.id,
          amountGross: price,
          commission,
          amountNet: net,
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
    throw new ConflictException('Deprecated: requests are auto-accepted at creation');
  }

  async reject(id: string, currentUserId?: string): Promise<TrainingRequest> {
    throw new ConflictException('Deprecated: requests are auto-accepted at creation');
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
