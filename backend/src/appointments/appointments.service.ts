import { Injectable, NotFoundException, ConflictException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Appointment, AppointmentStatus } from '@prisma/client';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateAppointmentDto } from './dto/update-appointment.dto';

@Injectable()
export class AppointmentsService {
  constructor(private prisma: PrismaService) {}

  async create(createAppointmentDto: CreateAppointmentDto): Promise<Appointment> {
    // Verify gymer and coach exist
    const [gymer, coach] = await Promise.all([
      this.prisma.gymer.findUnique({ where: { id: createAppointmentDto.gymerId } }),
      this.prisma.coach.findUnique({ where: { id: createAppointmentDto.coachId } }),
    ]);

    if (!gymer) {
      throw new NotFoundException('Gymer not found');
    }

    if (!coach) {
      throw new NotFoundException('Coach not found');
    }

    // Check for scheduling conflicts if date is provided
    if (createAppointmentDto.date) {
      const appointmentDate = new Date(createAppointmentDto.date);
      const conflictingAppointment = await this.prisma.appointment.findFirst({
        where: {
          OR: [
            { gymerId: createAppointmentDto.gymerId },
            { coachId: createAppointmentDto.coachId },
          ],
          date: appointmentDate,
          status: {
            in: [AppointmentStatus.PENDING, AppointmentStatus.CONFIRMED],
          },
        },
      });

      if (conflictingAppointment) {
        throw new ConflictException('Time slot is already booked');
      }
    }

    return this.prisma.appointment.create({
      data: {
        ...createAppointmentDto,
        date: createAppointmentDto.date ? new Date(createAppointmentDto.date) : null,
      },
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
        workoutExercise: {
          include: {
            workoutPlan: true,
          },
        },
      },
    });
  }

  async findAll(gymerId?: string, coachId?: string, status?: AppointmentStatus): Promise<Appointment[]> {
    const where: any = {};

    if (gymerId) where.gymerId = gymerId;
    if (coachId) where.coachId = coachId;
    if (status) where.status = status;

    return this.prisma.appointment.findMany({
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
        workoutExercise: {
          include: {
            workoutPlan: true,
          },
        },
      },
      orderBy: {
        date: 'asc',
      },
    });
  }

  async findOne(id: string): Promise<Appointment> {
    const appointment = await this.prisma.appointment.findUnique({
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
        workoutExercise: {
          include: {
            workoutPlan: true,
          },
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException('Appointment not found');
    }

    return appointment;
  }

  async update(id: string, updateAppointmentDto: UpdateAppointmentDto, currentUserId?: string): Promise<Appointment> {
    const appointment = await this.findOne(id);

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
        (user?.gymerProfile?.id === appointment.gymerId) ||
        (user?.coachProfile?.id === appointment.coachId) ||
        (user?.role === 'ADMIN');

      if (!isOwner) {
        throw new ForbiddenException('You can only update your own appointments');
      }
    }

    // Check for scheduling conflicts if date is being updated
    if (updateAppointmentDto.date) {
      const appointmentDate = new Date(updateAppointmentDto.date);
      const conflictingAppointment = await this.prisma.appointment.findFirst({
        where: {
          id: { not: id },
          OR: [
            { gymerId: appointment.gymerId },
            { coachId: appointment.coachId },
          ],
          date: appointmentDate,
          status: {
            in: [AppointmentStatus.PENDING, AppointmentStatus.CONFIRMED],
          },
        },
      });

      if (conflictingAppointment) {
        throw new ConflictException('Time slot is already booked');
      }
    }

    return this.prisma.appointment.update({
      where: { id },
      data: {
        ...updateAppointmentDto,
        date: updateAppointmentDto.date ? new Date(updateAppointmentDto.date) : undefined,
      },
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
        workoutExercise: {
          include: {
            workoutPlan: true,
          },
        },
      },
    });
  }

  async remove(id: string, currentUserId?: string): Promise<Appointment> {
    const appointment = await this.findOne(id);

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
        (user?.gymerProfile?.id === appointment.gymerId) ||
        (user?.coachProfile?.id === appointment.coachId) ||
        (user?.role === 'ADMIN');

      if (!isOwner) {
        throw new ForbiddenException('You can only delete your own appointments');
      }
    }

    return this.prisma.appointment.delete({
      where: { id },
    });
  }

  async getUpcomingAppointments(userId: string): Promise<Appointment[]> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        coachProfile: true,
        gymerProfile: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const where: any = {
      date: {
        gte: new Date(),
      },
      status: {
        in: [AppointmentStatus.PENDING, AppointmentStatus.CONFIRMED],
      },
    };

    if (user.coachProfile) {
      where.coachId = user.coachProfile.id;
    } else if (user.gymerProfile) {
      where.gymerId = user.gymerProfile.id;
    } else {
      return [];
    }

    return this.prisma.appointment.findMany({
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
        workoutExercise: {
          include: {
            workoutPlan: true,
          },
        },
      },
      orderBy: {
        date: 'asc',
      },
      take: 10,
    });
  }
}
