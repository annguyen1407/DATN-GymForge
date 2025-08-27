import { Injectable, ConflictException, UnauthorizedException, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { User, UserRole } from '@prisma/client';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { JwtPayload } from './strategies/jwt.strategy';
import { EmailService } from '../email/email.service';
import { TokenCacheService } from '../redis/token-cache.service';
import * as bcrypt from 'bcryptjs';


@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private emailService: EmailService,
    private tokenCache: TokenCacheService,
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

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    const user = await this.prisma.user.create({
      data: {
        email: registerDto.email,
        username: registerDto.username,
        password: hashedPassword,
        name: registerDto.name,
        role: registerDto.role || UserRole.GYMER,
        isEmailVerified: false,
        emailVerificationOTP: otp,
        emailVerificationOTPExpires: otpExpires,
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

    // Send verification OTP
    try {
      await this.emailService.sendVerificationOTP(
        user.email!,
        user.name || 'User',
        otp,
      );
    } catch (error) {
      console.error('Failed to send verification OTP:', error);
      // Don't throw error here, user is still created
    }

    return await this.generateAuthResponse(user);
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

    return await this.generateAuthResponse(user);
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

  async verifyEmail(email: string, otp: string): Promise<{ message: string }> {
    const user = await this.prisma.user.findFirst({
      where: {
        email: email,
        emailVerificationOTP: otp,
        emailVerificationOTPExpires: {
          gt: new Date(),
        },
      },
    });

    if (!user) {
      throw new BadRequestException('Invalid or expired OTP code');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        isEmailVerified: true,
        emailVerificationOTP: null,
        emailVerificationOTPExpires: null,
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

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordResetOTP: otp,
        passwordResetOTPExpires: otpExpires,
      },
    });

    try {
      await this.emailService.sendPasswordResetOTP(
        user.email!,
        user.name || 'User',
        otp,
      );
    } catch (error) {
      console.error('Failed to send password reset email:', error);
      return { message: 'Failed to send password reset email. Please try again later.' };
    }

    return { message: 'Password reset code has been sent to your email address. Please check your inbox.' };
  }

  async resetPassword(otp: string, email: string, newPassword: string): Promise<{ message: string }> {
    const user = await this.prisma.user.findFirst({
      where: {
        email: email,
        passwordResetOTP: otp,
        passwordResetOTPExpires: {
          gt: new Date(),
        },
      },
    });

    if (!user) {
      throw new BadRequestException('Invalid or expired OTP code');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        passwordResetOTP: null,
        passwordResetOTPExpires: null,
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

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        emailVerificationOTP: otp,
        emailVerificationOTPExpires: otpExpires,
      },
    });

    try {
      await this.emailService.sendVerificationOTP(
        user.email!,
        user.name || 'User',
        otp,
      );
    } catch (error) {
      console.error('Failed to send verification email:', error);
    }

    return { message: 'If the email exists, a verification email has been sent' };
  }

  async googleLogin(user: User): Promise<AuthResponseDto> {
    return await this.generateAuthResponse(user);
  }

  async logout(refresh_token: string): Promise<void> {
    try {
      // Verify refresh token
      const payload = await this.jwtService.verify(refresh_token, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET')
      });
      // Remove refresh token from Redis
      await this.tokenCache.removeRefreshToken(refresh_token);
    } catch (error) {
      // If token is invalid, do nothing
      this.logger.debug(`Invalid refresh token provided for logout: ${refresh_token}`);
      return;
    }
  }

  async refreshTokens(refresh_token: string): Promise<AuthResponseDto> {
    try {
      // Verify refresh token with the correct secret
      const payload = await this.jwtService.verify(refresh_token, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET')
      });
      // Check Redis for token validity
      const storedUserId = await this.tokenCache.getUserIdByRefreshToken(refresh_token);
      if (!storedUserId || storedUserId !== payload.sub) {
        throw new UnauthorizedException('Invalid refresh token');
      }
      // Remove old refresh token (token rotation)
      await this.tokenCache.removeRefreshToken(refresh_token);
      // Issue new tokens
      const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
      if (!user) throw new UnauthorizedException('User not found');
      return await this.generateAuthResponse(user);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  private generateAccessToken(payload: JwtPayload): string {
    return this.jwtService.sign(payload, {
      expiresIn: '15m' // Short-lived access token
    });
  }

  private generateRefreshToken(payload: JwtPayload): string {
    return this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: '7d' // Long-lived refresh token
    });
  }

  private async generateAuthResponse(user: User): Promise<AuthResponseDto> {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    // Use existing JWT_SECRET with different expiration times
    const access_token = this.generateAccessToken(payload);
    const refresh_token = this.generateRefreshToken(payload);

    // Store refresh token in Redis (7 days)
    await this.tokenCache.storeRefreshToken(user.id, refresh_token, 7 * 24 * 60 * 60);

    // Remove sensitive information
    const { password, ...userWithoutPassword } = user;

    return {
      access_token,
      refresh_token,
      user: userWithoutPassword,
      expires_in: '15m',
    };
  }
}
