import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Gymer } from '@prisma/client';
import { CreateGymerDto } from './dto/create-gymer.dto';
import { UpdateGymerDto } from './dto/update-gymer.dto';

@Injectable()
export class GymersService {
  constructor(private prisma: PrismaService) {}

  async create(createGymerDto: CreateGymerDto): Promise<Gymer> {
    // Check if user exists and has GYMER role
    const user = await this.prisma.user.findUnique({
      where: { id: createGymerDto.userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.role !== 'GYMER') {
      throw new ConflictException('User must have GYMER role');
    }

    // Check if gymer profile already exists
    const existingGymer = await this.prisma.gymer.findUnique({
      where: { userId: createGymerDto.userId },
    });

    if (existingGymer) {
      throw new ConflictException('Gymer profile already exists for this user');
    }

    return this.prisma.gymer.create({
      data: createGymerDto,
      include: {
        user: true,
      },
    });
  }

  async findAll(): Promise<Gymer[]> {
    return this.prisma.gymer.findMany({
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phoneNumber: true,
            profilePicture: true,
            weight: true,
            height: true,
            goal: true,
            expType: true,
          },
        },
        _count: {
          select: {
            appointments: true,
            feedbacks: true,
            trainingRequestsReceived: true,
          },
        },
      },
    });
  }

  async findOne(id: string): Promise<Gymer> {
    const gymer = await this.prisma.gymer.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phoneNumber: true,
            profilePicture: true,
            weight: true,
            height: true,
            goal: true,
            expType: true,
            biography: true,
          },
        },
        appointments: {
          include: {
            coach: {
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
            coach: {
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
        trainingRequestsReceived: {
          include: {
            coach: {
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
      },
    });

    if (!gymer) {
      throw new NotFoundException('Gymer not found');
    }

    return gymer;
  }

  async findByUserId(userId: string): Promise<Gymer | null> {
    return this.prisma.gymer.findUnique({
      where: { userId },
      include: {
        user: true,
      },
    });
  }

  async update(id: string, updateGymerDto: UpdateGymerDto): Promise<Gymer> {
    const gymer = await this.findOne(id);

    return this.prisma.gymer.update({
      where: { id },
      data: updateGymerDto,
      include: {
        user: true,
      },
    });
  }

  async remove(id: string): Promise<Gymer> {
    const gymer = await this.findOne(id);

    return this.prisma.gymer.delete({
      where: { id },
    });
  }
}
