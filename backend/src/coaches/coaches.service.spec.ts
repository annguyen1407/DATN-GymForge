import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ConflictException } from '@nestjs/common';
import { CoachesService } from './coaches.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserRole } from '@prisma/client';
import { EmailService } from '../email/email.service';

describe('CoachesService', () => {
  let service: CoachesService;
  let prismaService: PrismaService;
  let emailService: EmailService;

  const mockUser = {
    id: 'user-id',
    email: 'coach@example.com',
    role: UserRole.COACH,
    name: 'Coach User',
  };

  const mockCoach = {
    id: 'coach-id',
    userId: 'user-id',
    certification: 'NASM Certified',
    status: 'Active',
    averageRating: 4.5,
    feedbackCount: 10,
    user: mockUser,
  };

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    coach: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    feedback: {
      findMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    const emailMock: Partial<EmailService> = { sendCoachApprovedNotification: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CoachesService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: EmailService, useValue: emailMock },
      ],
    }).compile();

    service = module.get<CoachesService>(CoachesService);
    prismaService = module.get<PrismaService>(PrismaService);
    emailService = module.get<EmailService>(EmailService) as any;
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    const createCoachDto = {
      userId: 'user-id',
      certification: 'NASM Certified',
      status: 'Active',
    };

    it('should create a coach with PENDING status and not grant premium immediately', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      mockPrismaService.coach.findUnique.mockResolvedValue(null);
      mockPrismaService.coach.create.mockResolvedValue({ ...mockCoach, status: 'PENDING' });

      const result = await service.create(createCoachDto as any);

      expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
        where: { id: createCoachDto.userId },
      });
      expect(mockPrismaService.coach.findUnique).toHaveBeenCalledWith({
        where: { userId: createCoachDto.userId },
      });
      expect(mockPrismaService.coach.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ userId: createCoachDto.userId, certification: createCoachDto.certification, status: 'PENDING' }),
        include: { user: true },
      });
      expect(result.status).toBe('PENDING');
      expect(mockPrismaService.user.update).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException if user does not exist', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(service.create(createCoachDto)).rejects.toThrow(NotFoundException);
    });

    it('should throw ConflictException if user is not a COACH', async () => {
      const nonCoachUser = { ...mockUser, role: UserRole.GYMER };
      mockPrismaService.user.findUnique.mockResolvedValue(nonCoachUser);

      await expect(service.create(createCoachDto)).rejects.toThrow(ConflictException);
    });

    it('should throw ConflictException if coach profile already exists', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      mockPrismaService.coach.findUnique.mockResolvedValue(mockCoach);
      await expect(service.create(createCoachDto)).rejects.toThrow(ConflictException);
    });
  });

  describe('approve', () => {
    it('sets coach ACTIVE, computes price, sends email, and grants premium to user', async () => {
      (mockPrismaService as any).coach.findUnique.mockResolvedValue({ id: 'coach-id', userId: 'user-id', status: 'PENDING', user: { id: 'user-id', email: 'e', name: 'n' } });
      (mockPrismaService as any).coach.update.mockResolvedValue({ id: 'coach-id', userId: 'user-id', status: 'ACTIVE', user: { id: 'user-id', email: 'e', name: 'n' } });
      (mockPrismaService as any).adminConfig = { findUnique: jest.fn().mockResolvedValue({ basePriceX: 10, ratingMultiplier: 0.2 }) };

      const res = await service.approve('coach-id');

      expect(res.status).toBe('ACTIVE');
      expect((mockPrismaService as any).user.update).toHaveBeenCalledWith({
        where: { id: 'user-id' },
        data: { premiumStatus: true, premiumExpiresAt: null },
      });
      expect((emailService as any).sendCoachApprovedNotification).toHaveBeenCalled();
    });
  });

  describe('findAll', () => {
    it('should return all coaches', async () => {
      const coaches = [mockCoach];
      mockPrismaService.coach.findMany.mockResolvedValue(coaches);

      const result = await service.findAll();

      expect(mockPrismaService.coach.findMany).toHaveBeenCalledWith(expect.objectContaining({
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
      }));
      expect(result).toEqual(coaches);
    });
  });

  describe('findOne', () => {
    it('should return a coach by id', async () => {
      mockPrismaService.coach.findUnique.mockResolvedValue(mockCoach);

      const result = await service.findOne('coach-id');

      expect(mockPrismaService.coach.findUnique).toHaveBeenCalledWith({
        where: { id: 'coach-id' },
        include: expect.any(Object),
      });
      expect(result).toEqual(mockCoach);
    });

    it('should throw NotFoundException if coach not found', async () => {
      mockPrismaService.coach.findUnique.mockResolvedValue(null);

      await expect(service.findOne('invalid-id')).rejects.toThrow(NotFoundException);
    });
  });

  describe('findByUserId', () => {
    it('should return a coach by user id', async () => {
      mockPrismaService.coach.findUnique.mockResolvedValue(mockCoach);

      const result = await service.findByUserId('user-id');

      expect(mockPrismaService.coach.findUnique).toHaveBeenCalledWith({
        where: { userId: 'user-id' },
        include: { user: true },
      });
      expect(result).toEqual(mockCoach);
    });

    it('should return null if coach not found', async () => {
      mockPrismaService.coach.findUnique.mockResolvedValue(null);

      const result = await service.findByUserId('invalid-user-id');

      expect(result).toBeNull();
    });
  });

  describe('update', () => {
    const updateCoachDto = {
      certification: 'Updated Certification',
      status: 'Updated Status',
    };

    it('should update a coach successfully', async () => {
      mockPrismaService.coach.findUnique.mockResolvedValue(mockCoach);
      const updatedCoach = { ...mockCoach, ...updateCoachDto };
      mockPrismaService.coach.update.mockResolvedValue(updatedCoach);

      const result = await service.update('coach-id', updateCoachDto);

      expect(mockPrismaService.coach.update).toHaveBeenCalledWith({
        where: { id: 'coach-id' },
        data: updateCoachDto,
        include: { user: true },
      });
      expect(result).toEqual(updatedCoach);
    });

    it('should throw NotFoundException if coach not found', async () => {
      mockPrismaService.coach.findUnique.mockResolvedValue(null);

      await expect(service.update('invalid-id', updateCoachDto)).rejects.toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    it('should delete a coach successfully', async () => {
      mockPrismaService.coach.findUnique.mockResolvedValue(mockCoach);
      mockPrismaService.coach.delete.mockResolvedValue(mockCoach);

      const result = await service.remove('coach-id');

      expect(mockPrismaService.coach.delete).toHaveBeenCalledWith({
        where: { id: 'coach-id' },
      });
      expect(result).toEqual(mockCoach);
    });

    it('should throw NotFoundException if coach not found', async () => {
      mockPrismaService.coach.findUnique.mockResolvedValue(null);

      await expect(service.remove('invalid-id')).rejects.toThrow(NotFoundException);
    });
  });

  describe('updateRating', () => {
    it('should update coach rating based on feedbacks', async () => {
      const feedbacks = [
        { rating: 4.0 },
        { rating: 5.0 },
        { rating: 4.5 },
      ];
      mockPrismaService.feedback.findMany.mockResolvedValue(feedbacks);
      mockPrismaService.coach.update.mockResolvedValue(mockCoach);

      await service.updateRating('coach-id');

      expect(mockPrismaService.feedback.findMany).toHaveBeenCalledWith({
        where: { coachId: 'coach-id' },
        select: { rating: true },
      });
      expect(mockPrismaService.coach.update).toHaveBeenCalledWith({
        where: { id: 'coach-id' },
        data: {
          averageRating: 4.5,
          feedbackCount: 3,
        },
      });
    });

    it('should not update rating if no feedbacks exist', async () => {
      mockPrismaService.feedback.findMany.mockResolvedValue([]);

      await service.updateRating('coach-id');

      expect(mockPrismaService.coach.update).not.toHaveBeenCalled();
    });
  });
});
