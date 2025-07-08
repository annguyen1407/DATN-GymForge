import { Injectable, NotFoundException, ConflictException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CoachesService } from '../coaches/coaches.service';
import { Feedback } from '@prisma/client';
import { CreateFeedbackDto } from './dto/create-feedback.dto';
import { UpdateFeedbackDto } from './dto/update-feedback.dto';

@Injectable()
export class FeedbacksService {
  constructor(
    private prisma: PrismaService,
    private coachesService: CoachesService,
  ) {}

  async create(createFeedbackDto: CreateFeedbackDto): Promise<Feedback> {
    // Verify gymer and coach exist
    const [gymer, coach] = await Promise.all([
      this.prisma.gymer.findUnique({ where: { id: createFeedbackDto.gymerId } }),
      this.prisma.coach.findUnique({ where: { id: createFeedbackDto.coachId } }),
    ]);

    if (!gymer) {
      throw new NotFoundException('Gymer not found');
    }

    if (!coach) {
      throw new NotFoundException('Coach not found');
    }

    // Check if feedback already exists from this gymer to this coach
    const existingFeedback = await this.prisma.feedback.findFirst({
      where: {
        gymerId: createFeedbackDto.gymerId,
        coachId: createFeedbackDto.coachId,
      },
    });

    if (existingFeedback) {
      throw new ConflictException('Feedback already exists from this gymer to this coach');
    }

    const feedback = await this.prisma.feedback.create({
      data: createFeedbackDto,
      include: {
        gymer: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
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
              },
            },
          },
        },
      },
    });

    // Update coach's average rating
    await this.coachesService.updateRating(createFeedbackDto.coachId);

    return feedback;
  }

  async findAll(gymerId?: string, coachId?: string): Promise<Feedback[]> {
    const where: any = {};

    if (gymerId) where.gymerId = gymerId;
    if (coachId) where.coachId = coachId;

    return this.prisma.feedback.findMany({
      where,
      include: {
        gymer: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
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
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(id: string): Promise<Feedback> {
    const feedback = await this.prisma.feedback.findUnique({
      where: { id },
      include: {
        gymer: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
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
              },
            },
          },
        },
      },
    });

    if (!feedback) {
      throw new NotFoundException('Feedback not found');
    }

    return feedback;
  }

  async findByCoach(coachId: string): Promise<Feedback[]> {
    return this.prisma.feedback.findMany({
      where: { coachId },
      include: {
        gymer: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async update(id: string, updateFeedbackDto: UpdateFeedbackDto, currentUserId?: string): Promise<Feedback> {
    const feedback = await this.findOne(id);

    // Check permissions - only the gymer who created the feedback or admin can update
    if (currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
        include: { gymerProfile: true },
      });

      const isOwner = 
        (user?.gymerProfile?.id === feedback.gymerId) ||
        (user?.role === 'ADMIN');

      if (!isOwner) {
        throw new ForbiddenException('You can only update your own feedback');
      }
    }

    const updatedFeedback = await this.prisma.feedback.update({
      where: { id },
      data: updateFeedbackDto,
      include: {
        gymer: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
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
              },
            },
          },
        },
      },
    });

    // Update coach's average rating if rating was changed
    if (updateFeedbackDto.rating !== undefined) {
      await this.coachesService.updateRating(feedback.coachId);
    }

    return updatedFeedback;
  }

  async remove(id: string, currentUserId?: string): Promise<Feedback> {
    const feedback = await this.findOne(id);

    // Check permissions - only the gymer who created the feedback or admin can delete
    if (currentUserId) {
      const user = await this.prisma.user.findUnique({
        where: { id: currentUserId },
        include: { gymerProfile: true },
      });

      const isOwner = 
        (user?.gymerProfile?.id === feedback.gymerId) ||
        (user?.role === 'ADMIN');

      if (!isOwner) {
        throw new ForbiddenException('You can only delete your own feedback');
      }
    }

    const deletedFeedback = await this.prisma.feedback.delete({
      where: { id },
    });

    // Update coach's average rating
    await this.coachesService.updateRating(feedback.coachId);

    return deletedFeedback;
  }

  async getCoachStats(coachId: string): Promise<{
    averageRating: number;
    totalFeedbacks: number;
    ratingDistribution: { [key: number]: number };
  }> {
    const feedbacks = await this.prisma.feedback.findMany({
      where: { 
        coachId,
        rating: { not: null },
      },
      select: { rating: true },
    });

    if (feedbacks.length === 0) {
      return {
        averageRating: 0,
        totalFeedbacks: 0,
        ratingDistribution: {},
      };
    }

    const ratings = feedbacks.map(f => f.rating!);
    const averageRating = ratings.reduce((sum, rating) => sum + rating, 0) / ratings.length;

    const ratingDistribution: { [key: number]: number } = {};
    for (let i = 1; i <= 5; i++) {
      ratingDistribution[i] = ratings.filter(rating => Math.floor(rating) === i).length;
    }

    return {
      averageRating: Math.round(averageRating * 100) / 100,
      totalFeedbacks: feedbacks.length,
      ratingDistribution,
    };
  }
}
