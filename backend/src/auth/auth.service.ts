import { Injectable, ConflictException, UnauthorizedException, NotFoundException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { User, UserRole } from '@prisma/client';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { JwtPayload } from './strategies/jwt.strategy';
import { EmailService } from '../email/email.service';
import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private emailService: EmailService,
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

    // Generate email verification token
    const emailVerificationToken = crypto.randomBytes(32).toString('hex');
    const emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

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
        isEmailVerified: false,
        emailVerificationToken,
        emailVerificationExpires,
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

    // Send verification email
    try {
      await this.emailService.sendVerificationEmail(
        user.email!,
        user.name || 'User',
        emailVerificationToken,
      );
    } catch (error) {
      console.error('Failed to send verification email:', error);
      // Don't throw error here, user is still created
    }

    return this.generateAuthResponse(user);
  }

  async login(loginDto: LoginDto): Promise<AuthResponseDto> {
    const user = await this.validateUser(loginDto.email, loginDto.password);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if email is verified (skip for OAuth users who don't have passwords)
    if (!user.isEmailVerified && user.password) {
      throw new UnauthorizedException('Please verify your email address before logging in. Check your inbox for the verification email.');
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

  async verifyEmail(token: string): Promise<{ message: string }> {
    const user = await this.prisma.user.findFirst({
      where: {
        emailVerificationToken: token,
        emailVerificationExpires: {
          gt: new Date(),
        },
      },
    });

    if (!user) {
      throw new BadRequestException('Invalid or expired verification token');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        isEmailVerified: true,
        emailVerificationToken: null,
        emailVerificationExpires: null,
      },
    });

    // Send welcome email
    try {
      await this.emailService.sendWelcomeEmail(user.email!, user.name || 'User');
    } catch (error) {
      console.error('Failed to send welcome email:', error);
    }

    return { message: 'Email verified successfully' };
  }

  async forgotPassword(email: string): Promise<{ message: string }> {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      return { message: 'No account found with this email address. Please check your email and try again.' };
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordResetToken: resetToken,
        passwordResetExpires: resetExpires,
      },
    });

    try {
      await this.emailService.sendPasswordResetEmail(
        user.email!,
        user.name || 'User',
        resetToken,
      );
    } catch (error) {
      console.error('Failed to send password reset email:', error);
      return { message: 'Failed to send password reset email. Please try again later.' };
    }

    return { message: 'Password reset link has been sent to your email address. Please check your inbox.' };
  }

  async resetPassword(token: string, newPassword: string): Promise<{ message: string }> {
    const user = await this.prisma.user.findFirst({
      where: {
        passwordResetToken: token,
        passwordResetExpires: {
          gt: new Date(),
        },
      },
    });

    if (!user) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        passwordResetToken: null,
        passwordResetExpires: null,
      },
    });

    // Send password changed notification
    try {
      await this.emailService.sendPasswordChangedNotification(
        user.email!,
        user.name || 'User',
      );
    } catch (error) {
      console.error('Failed to send password changed notification:', error);
    }

    return { message: 'Password reset successfully' };
  }

  async validateResetToken(token: string): Promise<User> {
    const user = await this.prisma.user.findFirst({
      where: {
        passwordResetToken: token,
        passwordResetExpires: {
          gt: new Date(),
        },
      },
    });

    if (!user) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    return user;
  }

  async resendVerificationEmail(email: string): Promise<{ message: string }> {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      return { message: 'If the email exists, a verification email has been sent' };
    }

    if (user.isEmailVerified) {
      throw new BadRequestException('Email is already verified');
    }

    const emailVerificationToken = crypto.randomBytes(32).toString('hex');
    const emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        emailVerificationToken,
        emailVerificationExpires,
      },
    });

    try {
      await this.emailService.sendVerificationEmail(
        user.email!,
        user.name || 'User',
        emailVerificationToken,
      );
    } catch (error) {
      console.error('Failed to send verification email:', error);
    }

    return { message: 'If the email exists, a verification email has been sent' };
  }

  async googleLogin(user: User): Promise<AuthResponseDto> {
    return this.generateAuthResponse(user);
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
