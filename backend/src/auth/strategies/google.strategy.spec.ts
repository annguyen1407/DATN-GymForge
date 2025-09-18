import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { GoogleStrategy } from './google.strategy';
import { AuthService } from '../auth.service';
import { PrismaService } from '../../prisma/prisma.service';
import { UserRole } from '@prisma/client';

describe('GoogleStrategy', () => {
  let strategy: GoogleStrategy;
  let authService: jest.Mocked<AuthService>;
  let prismaService: jest.Mocked<PrismaService>;
  let configService: jest.Mocked<ConfigService>;

  const mockUser = {
    id: 'user-id',
    email: 'test@example.com',
    username: null,
    name: 'Test User',
    password: null,
    role: UserRole.GYMER,
    googleId: 'google-id-123',
    isEmailVerified: true,
    profilePicture: 'https://example.com/photo.jpg',
    emailVerificationToken: null,
    emailVerificationExpires: null,
    passwordResetToken: null,
    passwordResetExpires: null,
    facebookId: null,
    dateOfBirth: null,
    address: null,
    phoneNumber: null,
    premiumStatus: false,
    weight: null,
    height: null,
    biography: null,
    goal: null,
    oneRm: null,
    expType: null,
    sex: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockGoogleProfile = {
    id: 'google-id-123',
    name: {
      givenName: 'Test',
      familyName: 'User',
    },
    emails: [{ value: 'test@example.com' }],
    photos: [{ value: 'https://example.com/photo.jpg' }],
  };

  beforeEach(async () => {
    const mockConfigService = {
      get: jest.fn(),
    } as any;

    (mockConfigService.get as jest.Mock).mockImplementation((key: string) => {
      switch (key) {
        case 'GOOGLE_CLIENT_ID':
          return 'mock-client-id';
        case 'GOOGLE_CLIENT_SECRET':
          return 'mock-client-secret';
        case 'GOOGLE_CALLBACK_URL':
          return 'http://localhost:3000/auth/google/callback';
        default:
          return undefined;
      }
    });

    const mockAuthService = {};

    const mockPrismaService = {
      user: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      gymer: {
        create: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GoogleStrategy,
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
        {
          provide: AuthService,
          useValue: mockAuthService,
        },
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
      ],
    }).compile();

    strategy = module.get<GoogleStrategy>(GoogleStrategy);
    authService = module.get(AuthService);
    prismaService = module.get(PrismaService);
    configService = module.get(ConfigService);

    // Mock config values are set on mockConfigService before module compilation
  });

  it('should be defined', () => {
    expect(strategy).toBeDefined();
  });

  describe('validate', () => {
    it('should return existing user with Google ID', async () => {
      const done = jest.fn();
      (prismaService.user.findFirst as any).mockResolvedValue(mockUser);

      await strategy.validate('access-token', 'refresh-token', mockGoogleProfile, done);

      expect(prismaService.user.findFirst).toHaveBeenCalledWith({
        where: { googleId: mockGoogleProfile.id, isDeleted: false },
      });
      expect(done).toHaveBeenCalledWith(null, mockUser);
    });

    it('should link Google account to existing user with same email', async () => {
      const done = jest.fn();
      const existingUser = { ...mockUser, googleId: null };
      const updatedUser = { ...mockUser, googleId: mockGoogleProfile.id };

      (prismaService.user.findFirst as any).mockResolvedValue(null);
      (prismaService.user.findUnique as any).mockResolvedValue(existingUser);
      (prismaService.user.update as any).mockResolvedValue(updatedUser);

      await strategy.validate('access-token', 'refresh-token', mockGoogleProfile, done);

      expect(prismaService.user.findFirst).toHaveBeenCalledWith({
        where: { googleId: mockGoogleProfile.id, isDeleted: false },
      });
      expect(prismaService.user.findUnique).toHaveBeenCalledWith({
        where: { email: mockGoogleProfile.emails[0].value },
      });
      expect(prismaService.user.update).toHaveBeenCalledWith({
        where: { id: existingUser.id },
        data: {
          googleId: mockGoogleProfile.id,
          profilePicture: mockGoogleProfile.photos[0].value,
          isEmailVerified: true,
        },
      });
      expect(done).toHaveBeenCalledWith(null, updatedUser);
    });

    it('should create new user for new Google account', async () => {
      const done = jest.fn();
      const newUser = { ...mockUser, id: 'new-user-id' };

      (prismaService.user.findFirst as any).mockResolvedValue(null);
      (prismaService.user.findUnique as any).mockResolvedValue(null);
      (prismaService.user.create as any).mockResolvedValue(newUser);
      (prismaService.gymer.create as any).mockResolvedValue({ id: 'gymer-id', userId: newUser.id });

      await strategy.validate('access-token', 'refresh-token', mockGoogleProfile, done);

      expect(prismaService.user.create).toHaveBeenCalledWith({
        data: {
          email: mockGoogleProfile.emails[0].value,
          googleId: mockGoogleProfile.id,
          name: `${mockGoogleProfile.name.givenName} ${mockGoogleProfile.name.familyName}`,
          profilePicture: mockGoogleProfile.photos[0].value,
          role: UserRole.GYMER,
          isEmailVerified: true,
        },
      });
      expect(prismaService.gymer.create).toHaveBeenCalledWith({
        data: {
          userId: newUser.id,
        },
      });
      expect(done).toHaveBeenCalledWith(null, newUser);
    });

    it('should handle errors during validation', async () => {
      const done = jest.fn();
      const error = new Error('Database error');

      (prismaService.user.findFirst as any).mockRejectedValue(error);

      await strategy.validate('access-token', 'refresh-token', mockGoogleProfile, done);

      expect(done).toHaveBeenCalledWith(error, false);
    });
  });
});
