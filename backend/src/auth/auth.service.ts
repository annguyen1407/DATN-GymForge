import { Injectable, ConflictException, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { User, UserRole } from '@prisma/client';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { JwtPayload } from './strategies/jwt.strategy';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(registerDto: RegisterDto): Promise<AuthResponseDto> {
    // Check if user exists by email or username
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: registerDto.email },
          { username: registerDto.username },
        ],
      },
    });

    if (existingUser) {
      throw new ConflictException('User with this email or username already exists');
    }

    const hashedPassword = await bcrypt.hash(registerDto.password, 12);

    const user = await this.prisma.user.create({
      data: {
        email: registerDto.email,
        username: registerDto.username,
        password: hashedPassword,
        name: registerDto.name,
        phoneNumber: registerDto.phoneNumber,
        role: registerDto.role || UserRole.GYMER,
        dateOfBirth: registerDto.dateOfBirth ? new Date(registerDto.dateOfBirth) : null,
        sex: registerDto.sex,
        address: registerDto.address,
        weight: registerDto.weight,
        height: registerDto.height,
        goal: registerDto.goal,
        expType: registerDto.expType,
        biography: registerDto.biography,
      },
    });

    // Create profile based on role
    if (user.role === UserRole.COACH) {
      await this.prisma.coach.create({
        data: {
          userId: user.id,
        },
      });
    } else if (user.role === UserRole.GYMER) {
      await this.prisma.gymer.create({
        data: {
          userId: user.id,
        },
      });
    }

    return this.generateAuthResponse(user);
  }

  async login(loginDto: LoginDto): Promise<AuthResponseDto> {
    const user = await this.validateUser(loginDto.email, loginDto.password);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.generateAuthResponse(user);
  }

  async validateUser(email: string, password: string): Promise<User | null> {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (user && user.password && await bcrypt.compare(password, user.password)) {
      return user;
    }

    return null;
  }

  async validateUserById(id: string): Promise<User | null> {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    return user;
  }

  async findUserById(id: string): Promise<User> {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  private generateAuthResponse(user: User): AuthResponseDto {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    const access_token = this.jwtService.sign(payload);
    const expires_in = this.configService.get<string>('JWT_EXPIRES_IN') || '24h';

    // Remove sensitive information
    const { password, ...userWithoutPassword } = user;

    return {
      access_token,
      user: userWithoutPassword,
      expires_in,
    };
  }
}
