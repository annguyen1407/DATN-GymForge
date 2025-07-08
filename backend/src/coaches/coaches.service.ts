import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Coach, User } from '@prisma/client';
import { CreateCoachDto } from './dto/create-coach.dto';
import { UpdateCoachDto } from './dto/update-coach.dto';

@Injectable()
export class CoachesService {
  constructor(private prisma: PrismaService) {}

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

    // Check if coach profile already exists
    const existingCoach = await this.prisma.coach.findUnique({
      where: { userId: createCoachDto.userId },
    });

    if (existingCoach) {
      throw new ConflictException('Coach profile already exists for this user');
    }

    return this.prisma.coach.create({
      data: createCoachDto,
      include: {
        user: true,
      },
    });
  }

  async findAll(): Promise<Coach[]> {
    return this.prisma.coach.findMany({
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
        _count: {
          select: {
            appointments: true,
            feedbacks: true,
            trainingRequestsSent: true,
          },
        },
      },
    });
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
    const coach = await this.findOne(id);

    return this.prisma.coach.update({
      where: { id },
      data: updateCoachDto,
      include: {
        user: true,
      },
    });
  }

  async remove(id: string): Promise<Coach> {
    const coach = await this.findOne(id);

    return this.prisma.coach.delete({
      where: { id },
    });
  }

  async updateRating(coachId: string): Promise<void> {
    const feedbacks = await this.prisma.feedback.findMany({
      where: { coachId },
      select: { rating: true },
    });

    if (feedbacks.length > 0) {
      const totalRating = feedbacks.reduce((sum, feedback) => sum + (feedback.rating || 0), 0);
      const averageRating = totalRating / feedbacks.length;

      await this.prisma.coach.update({
        where: { id: coachId },
        data: {
          averageRating,
          feedbackCount: feedbacks.length,
        },
      });
    }
  }
}
