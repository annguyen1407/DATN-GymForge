import { Injectable, NotFoundException, ConflictException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TrainingRequest, TrainingRequestStatus } from '@prisma/client';
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

    if (!gymer) {
      throw new NotFoundException('Gymer not found');
    }

    if (!coach) {
      throw new NotFoundException('Coach not found');
    }

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

    return this.prisma.trainingRequest.create({
      data: createTrainingRequestDto,
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
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
        include: { coachProfile: true },
      });

      if (user?.coachProfile?.id !== trainingRequest.coachId && user?.role !== 'ADMIN') {
        throw new ForbiddenException('Only the coach can accept this training request');
      }
    }

    if (trainingRequest.status !== TrainingRequestStatus.PENDING) {
      throw new ConflictException('Only pending requests can be accepted');
    }

    return this.prisma.trainingRequest.update({
      where: { id },
      data: { status: TrainingRequestStatus.ACCEPTED },
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

  async reject(id: string, currentUserId?: string): Promise<TrainingRequest> {
    const trainingRequest = await this.findOne(id);

    // Only the coach can reject the request
    if (currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
        include: { coachProfile: true },
      });

      if (user?.coachProfile?.id !== trainingRequest.coachId && user?.role !== 'ADMIN') {
        throw new ForbiddenException('Only the coach can reject this training request');
      }
    }

    if (trainingRequest.status !== TrainingRequestStatus.PENDING) {
      throw new ConflictException('Only pending requests can be rejected');
    }

    return this.prisma.trainingRequest.update({
      where: { id },
      data: { status: TrainingRequestStatus.REJECTED },
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
}
