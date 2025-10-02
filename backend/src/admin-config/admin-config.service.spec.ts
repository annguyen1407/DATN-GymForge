import { Test, TestingModule } from '@nestjs/testing';
import { AdminConfigService } from './admin-config.service';
import { BadRequestException } from '@nestjs/common';

describe('AdminConfigService', () => {
  let service: AdminConfigService;
  const prisma = {
    adminConfig: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    coach: {
      findMany: jest.fn(),
      update: jest.fn(),
    },
  } as any;

  beforeEach(async () => {
    jest.clearAllMocks();
    // defaults to avoid undefined
    prisma.coach.findMany.mockResolvedValue([]);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminConfigService,
        { provide: require('../prisma/prisma.service').PrismaService, useValue: prisma },
      ],
    }).compile();
    service = module.get(AdminConfigService);
  });

  it('get(): creates default when none exists', async () => {
    prisma.adminConfig.findUnique.mockResolvedValueOnce(null);
    const def = {
      id: 'singleton',
      basePriceX: 10,
      ratingMultiplier: 0.2,
      commissionRate: 0.1,
      coachCancelLockDays: 30,
    };
    prisma.adminConfig.create.mockResolvedValueOnce(def);

    const res = await service.get();
    expect(prisma.adminConfig.findUnique).toHaveBeenCalledWith({ where: { id: 'singleton' } });
    expect(prisma.adminConfig.create).toHaveBeenCalled();
    expect(res).toEqual(def);
  });

  it('get(): returns existing when present', async () => {
    const existing = { id: 'singleton', basePriceX: 12, ratingMultiplier: 0.25, commissionRate: 0.15, coachCancelLockDays: 20 };
    prisma.adminConfig.findUnique.mockResolvedValueOnce(existing);

    const res = await service.get();
    expect(prisma.adminConfig.create).not.toHaveBeenCalled();
    expect(res).toEqual(existing);
  });

  it('update(): validates basePriceX >= 0', async () => {
    await expect(service.update({ basePriceX: -1 })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('update(): validates ratingMultiplier in [0,1]', async () => {
    await expect(service.update({ ratingMultiplier: -0.1 })).rejects.toBeInstanceOf(BadRequestException);
    await expect(service.update({ ratingMultiplier: 1.1 })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('update(): validates commissionRate in [0,1]', async () => {
    await expect(service.update({ commissionRate: -0.1 })).rejects.toBeInstanceOf(BadRequestException);
    await expect(service.update({ commissionRate: 1.1 })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('update(): validates coachCancelLockDays >= 0', async () => {
    await expect(service.update({ coachCancelLockDays: -5 })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('update(): updates after ensuring config exists', async () => {
    // get() is called inside update() → ensure it returns something
    prisma.adminConfig.findUnique.mockResolvedValueOnce({ id: 'singleton', basePriceX: 10, ratingMultiplier: 0.2 });
    const updated = { id: 'singleton', basePriceX: 20, ratingMultiplier: 0.2 } as any;
    prisma.adminConfig.update.mockResolvedValueOnce(updated);

    const res = await service.update({ basePriceX: 20 });
    expect(prisma.adminConfig.update).toHaveBeenCalledWith({ where: { id: 'singleton' }, data: { basePriceX: 20 } });
    expect(res).toEqual(updated);
  });

  it('update(): re-computes ACTIVE coaches\' trainingPrice when knobs change', async () => {
    // before config
    prisma.adminConfig.findUnique.mockResolvedValueOnce({ id: 'singleton', basePriceX: 10, ratingMultiplier: 0.2 });
    // updated config
    prisma.adminConfig.update.mockResolvedValueOnce({ id: 'singleton', basePriceX: 12, ratingMultiplier: 0.3 });
    // active coaches
    prisma.coach.findMany.mockResolvedValueOnce([
      { id: 'c1', averageRating: 4.5 },
      { id: 'c2', averageRating: 3.0 },
    ]);

    await service.update({ basePriceX: 12, ratingMultiplier: 0.3 });

    expect(prisma.coach.findMany).toHaveBeenCalledWith({ where: { status: 'ACTIVE' } });
    expect(prisma.coach.update).toHaveBeenCalledTimes(2);
  });
});

