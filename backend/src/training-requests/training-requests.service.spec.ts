import { ConflictException, NotFoundException } from '@nestjs/common';
import { TrainingRequestsService } from './training-requests.service';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentMethod, PaymentStatus, TrainingRequestStatus } from '@prisma/client';


describe('TrainingRequestsService (Option A gating)', () => {
  let service: TrainingRequestsService;
  const prisma: any = {
    gymer: { findUnique: jest.fn() },
    coach: { findUnique: jest.fn() },
    adminConfig: { findUnique: jest.fn() },
    trainingRequest: { findFirst: jest.fn(), create: jest.fn(), findUnique: jest.fn() },
    trainingPayment: { create: jest.fn() },
    coachEarning: { create: jest.fn() },
    $transaction: async (fn: any) => fn(prisma),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    service = new TrainingRequestsService(prisma as PrismaService);
  });

  it('throws when coach is not active', async () => {
    prisma.gymer.findUnique.mockResolvedValue({ id: 'g1', userId: 'ug1' });
    prisma.coach.findUnique.mockResolvedValue({ id: 'c1', status: 'PENDING', isOpenToTraining: true });

    await expect(service.create({ gymerId: 'g1', coachId: 'c1' } as any)).rejects.toBeInstanceOf(ConflictException);
  });

  it('throws when coach is not open to training', async () => {
    prisma.gymer.findUnique.mockResolvedValue({ id: 'g1', userId: 'ug1' });
    prisma.coach.findUnique.mockResolvedValue({ id: 'c1', status: 'ACTIVE', isOpenToTraining: false });

    await expect(service.create({ gymerId: 'g1', coachId: 'c1' } as any)).rejects.toBeInstanceOf(ConflictException);
  });
});

