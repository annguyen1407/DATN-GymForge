import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { EmailService } from '../email/email.service';
import { TokenCacheService } from '../redis/token-cache.service';
import { UserRole } from '@prisma/client';


describe('AuthService (coach approval gating)', () => {
  let service: AuthService;
  const prisma: Partial<PrismaService> = {
    coach: { findUnique: jest.fn() } as any,
  } as any;
  const jwt = { sign: jest.fn().mockReturnValue('token') } as any as JwtService;
  const config = { get: jest.fn().mockReturnValue('1h') } as any as ConfigService;
  const email = {} as any as EmailService;
  const cache: Partial<TokenCacheService> = {
    storeRefreshToken: jest.fn(),
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AuthService(prisma as any, jwt, config, email, cache as any);
  });

  it('blocks login() for unapproved coaches', async () => {
    const user: any = { id: 'u1', email: 'c@test.dev', role: UserRole.COACH, isEmailVerified: true };
    jest.spyOn<any, any>(service as any, 'validateUser').mockResolvedValue(user);
    (prisma.coach!.findUnique as any).mockResolvedValue({ status: 'PENDING' });

    await expect(service.login({ email: 'c@test.dev', password: 'x' } as any)).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('blocks googleLogin() for unapproved coaches', async () => {
    const user: any = { id: 'u1', email: 'c@test.dev', role: UserRole.COACH, isEmailVerified: true };
    (prisma.coach!.findUnique as any).mockResolvedValue({ status: 'PENDING' });

    await expect(service.googleLogin(user)).rejects.toBeInstanceOf(UnauthorizedException);
  });
});

