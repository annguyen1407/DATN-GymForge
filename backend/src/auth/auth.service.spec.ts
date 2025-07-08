import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

jest.mock('bcryptjs');

describe('AuthService', () => {
  let service: AuthService;
  let prismaService: PrismaService;
  let jwtService: JwtService;
  let configService: ConfigService;

  const mockUser = {
    id: 'user-id',
    email: 'test@example.com',
    username: 'testuser',
    password: 'hashedpassword',
    name: 'Test User',
    role: UserRole.GYMER,
    phoneNumber: null,
    profilePicture: null,
    dateOfBirth: null,
    address: null,
    premiumStatus: false,
    weight: null,
    height: null,
    biography: null,
    goal: null,
    oneRm: null,
    expType: null,
    sex: null,
  };

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    coach: {
      create: jest.fn(),
    },
    gymer: {
      create: jest.fn(),
    },
  };

  const mockJwtService = {
    sign: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    prismaService = module.get<PrismaService>(PrismaService);
    jwtService = module.get<JwtService>(JwtService);
    configService = module.get<ConfigService>(ConfigService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('register', () => {
    const registerDto = {
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
      username: 'testuser',
      role: UserRole.GYMER,
    };

    it('should register a new user successfully', async () => {
      mockPrismaService.user.findFirst.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashedpassword');
      mockPrismaService.user.create.mockResolvedValue(mockUser);
      mockPrismaService.gymer.create.mockResolvedValue({});
      mockJwtService.sign.mockReturnValue('jwt-token');
      mockConfigService.get.mockReturnValue('24h');

      const result = await service.register(registerDto);

      expect(mockPrismaService.user.findFirst).toHaveBeenCalledWith({
        where: {
          OR: [
            { email: registerDto.email },
            { username: registerDto.username },
          ],
        },
      });
      expect(bcrypt.hash).toHaveBeenCalledWith(registerDto.password, 12);
      expect(mockPrismaService.user.create).toHaveBeenCalled();
      expect(mockPrismaService.gymer.create).toHaveBeenCalled();
      expect(result).toHaveProperty('access_token', 'jwt-token');
      expect(result).toHaveProperty('user');
    });

    it('should throw ConflictException if user already exists', async () => {
      mockPrismaService.user.findFirst.mockResolvedValue(mockUser);

      await expect(service.register(registerDto)).rejects.toThrow(ConflictException);
    });

    it('should create coach profile for COACH role', async () => {
      const coachRegisterDto = { ...registerDto, role: UserRole.COACH };
      const coachUser = { ...mockUser, role: UserRole.COACH };

      mockPrismaService.user.findFirst.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashedpassword');
      mockPrismaService.user.create.mockResolvedValue(coachUser);
      mockPrismaService.coach.create.mockResolvedValue({});
      mockJwtService.sign.mockReturnValue('jwt-token');
      mockConfigService.get.mockReturnValue('24h');

      await service.register(coachRegisterDto);

      expect(mockPrismaService.coach.create).toHaveBeenCalledWith({
        data: { userId: coachUser.id },
      });
    });
  });

  describe('login', () => {
    const loginDto = {
      email: 'test@example.com',
      password: 'password123',
    };

    it('should login user successfully', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);
      mockJwtService.sign.mockReturnValue('jwt-token');
      mockConfigService.get.mockReturnValue('24h');

      const result = await service.login(loginDto);

      expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
        where: { email: loginDto.email },
      });
      expect(bcrypt.compare).toHaveBeenCalledWith(loginDto.password, mockUser.password);
      expect(result).toHaveProperty('access_token', 'jwt-token');
      expect(result).toHaveProperty('user');
    });

    it('should throw UnauthorizedException for invalid credentials', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(service.login(loginDto)).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for wrong password', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(service.login(loginDto)).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('validateUser', () => {
    it('should return user for valid credentials', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      const result = await service.validateUser('test@example.com', 'password123');

      expect(result).toEqual(mockUser);
    });

    it('should return null for invalid credentials', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      const result = await service.validateUser('test@example.com', 'password123');

      expect(result).toBeNull();
    });

    it('should return null for user without password', async () => {
      const userWithoutPassword = { ...mockUser, password: null };
      mockPrismaService.user.findUnique.mockResolvedValue(userWithoutPassword);

      const result = await service.validateUser('test@example.com', 'password123');

      expect(result).toBeNull();
    });
  });

  describe('validateUserById', () => {
    it('should return user for valid id', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.validateUserById('user-id');

      expect(result).toEqual(mockUser);
      expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'user-id' },
      });
    });

    it('should return null for invalid id', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      const result = await service.validateUserById('invalid-id');

      expect(result).toBeNull();
    });
  });
});
