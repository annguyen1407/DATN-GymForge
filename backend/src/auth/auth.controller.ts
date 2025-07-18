import { Controller, Post, Body, UseGuards, Get, Request, Query, Req, Res, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiExcludeEndpoint } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { ResendVerificationDto } from './dto/resend-verification.dto';
import { MessageResponseDto } from './dto/message-response.dto';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import { User } from '@prisma/client';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @ApiOperation({ summary: 'Register a new user' })
  @ApiResponse({ status: 201, description: 'User registered successfully', type: AuthResponseDto })
  @ApiResponse({ status: 409, description: 'User already exists' })
  async register(@Body() registerDto: RegisterDto): Promise<AuthResponseDto> {
    return this.authService.register(registerDto);
  }

  @Post('login')
  @ApiOperation({ summary: 'Login user' })
  @ApiResponse({ status: 200, description: 'Login successful', type: AuthResponseDto })
  @ApiResponse({ status: 401, description: 'Invalid credentials' })
  async login(@Body() loginDto: LoginDto): Promise<AuthResponseDto> {
    return this.authService.login(loginDto);
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({ status: 200, description: 'Profile retrieved successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getProfile(@CurrentUser() user: User) {
    return user;
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user information' })
  @ApiResponse({ status: 200, description: 'User information retrieved successfully' })
  async getCurrentUser(@CurrentUser() user: User) {
    return this.authService.findUserById(user.id);
  }

  @Post('verify-email')
  @ApiOperation({ summary: 'Verify email address (POST)' })
  @ApiResponse({ status: 200, description: 'Email verified successfully', type: MessageResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid or expired verification token' })
  async verifyEmail(@Body() verifyEmailDto: VerifyEmailDto): Promise<MessageResponseDto> {
    return this.authService.verifyEmail(verifyEmailDto.token);
  }

  @Get('verify-email')
  @ApiOperation({ summary: 'Verify email address (GET)' })
  @ApiResponse({ status: 200, description: 'Email verified successfully', type: MessageResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid or expired verification token' })
  async verifyEmailGet(@Query('token') token: string): Promise<MessageResponseDto> {
    if (!token) {
      throw new BadRequestException('Verification token is required');
    }
    return this.authService.verifyEmail(token);
  }

  @Post('forgot-password')
  @ApiOperation({ summary: 'Request password reset' })
  @ApiResponse({ status: 200, description: 'Password reset email sent if email exists', type: MessageResponseDto })
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto): Promise<MessageResponseDto> {
    return this.authService.forgotPassword(forgotPasswordDto.email);
  }

  @Post('reset-password')
  @ApiOperation({ summary: 'Reset password with token (POST)' })
  @ApiResponse({ status: 200, description: 'Password reset successfully', type: MessageResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid or expired reset token' })
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto): Promise<MessageResponseDto> {
    return this.authService.resetPassword(resetPasswordDto.token, resetPasswordDto.newPassword);
  }

  @Get('reset-password')
  @ApiOperation({ summary: 'Validate reset password token (GET)' })
  @ApiResponse({ status: 200, description: 'Token is valid, redirect to reset form' })
  @ApiResponse({ status: 400, description: 'Invalid or expired reset token' })
  async validateResetToken(@Query('token') token: string, @Res() res: any) {
    if (!token) {
      throw new BadRequestException('Reset token is required');
    }

    // Validate the token exists and is not expired
    const user = await this.authService.validateResetToken(token);

    // Redirect to frontend reset password form with token
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const redirectUrl = `${frontendUrl}/auth/new-password?token=${token}`;

    return res.redirect(redirectUrl);
  }

  @Post('resend-verification')
  @ApiOperation({ summary: 'Resend email verification' })
  @ApiResponse({ status: 200, description: 'Verification email sent if email exists', type: MessageResponseDto })
  @ApiResponse({ status: 400, description: 'Email is already verified' })
  async resendVerification(@Body() resendVerificationDto: ResendVerificationDto): Promise<MessageResponseDto> {
    return this.authService.resendVerificationEmail(resendVerificationDto.email);
  }

  @Get('google')
  @UseGuards(AuthGuard('google'))
  @ApiExcludeEndpoint()
  async googleAuth(@Req() req: any) {
    // This route initiates Google OAuth
  }

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  @ApiExcludeEndpoint()
  async googleAuthRedirect(@Req() req: any, @Res() res: any) {
    const authResponse = await this.authService.googleLogin(req.user);

    // Redirect to frontend with token
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const redirectUrl = `${frontendUrl}/auth/oauth-success?token=${authResponse.access_token}`;

    return res.redirect(redirectUrl);
  }
}
