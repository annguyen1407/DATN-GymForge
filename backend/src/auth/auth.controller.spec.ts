import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { UserRole } from '@prisma/client';

describe('AuthController', () => {
  let controller: AuthController;
  let authService: jest.Mocked<AuthService>;

  const mockUser = {
    id: 'user-id',
    email: 'test@example.com',
    username: 'testuser',
    name: 'Test User',
    role: UserRole.GYMER,
    password: 'hashed-password',
    isEmailVerified: false,
    emailVerificationToken: 'verification-token',
    emailVerificationExpires: new Date(Date.now() + 24 * 60 * 60 * 1000),
    passwordResetToken: null,
    passwordResetExpires: null,
    googleId: null,
    facebookId: null,
    profilePicture: null,
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

  const mockAuthResponse = {
    access_token: 'jwt-token',
    user: mockUser,
    expires_in: '24h',
  };

  beforeEach(async () => {
    const mockAuthService = {
      register: jest.fn(),
      login: jest.fn(),
      findUserById: jest.fn(),
      verifyEmail: jest.fn(),
      forgotPassword: jest.fn(),
      resetPassword: jest.fn(),
      resendVerificationEmail: jest.fn(),
      googleLogin: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: AuthService,
          useValue: mockAuthService,
        },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
    authService = module.get(AuthService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('register', () => {
    it('should register a new user', async () => {
      const registerDto = {
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        name: 'Test User',
        role: UserRole.GYMER,
        phoneNumber: null,
        dateOfBirth: null,
        sex: null,
        address: null,
        weight: null,
        height: null,
        goal: null,
        expType: null,
        biography: null,
      };

      authService.register.mockResolvedValue(mockAuthResponse);

      const result = await controller.register(registerDto);

      expect(authService.register).toHaveBeenCalledWith(registerDto);
      expect(result).toEqual(mockAuthResponse);
    });
  });

  describe('login', () => {
    it('should login a user', async () => {
      const loginDto = {
        email: 'test@example.com',
        password: 'password123',
      };

      authService.login.mockResolvedValue(mockAuthResponse);

      const result = await controller.login(loginDto);

      expect(authService.login).toHaveBeenCalledWith(loginDto);
      expect(result).toEqual(mockAuthResponse);
    });
  });

  describe('getProfile', () => {
    it('should return user profile', async () => {
      const result = await controller.getProfile(mockUser);

      expect(result).toEqual(mockUser);
    });
  });

  describe('getCurrentUser', () => {
    it('should return current user information', async () => {
      authService.findUserById.mockResolvedValue(mockUser);

      const result = await controller.getCurrentUser(mockUser);

      expect(authService.findUserById).toHaveBeenCalledWith(mockUser.id);
      expect(result).toEqual(mockUser);
    });
  });

  describe('verifyEmail', () => {
    it('should verify email address', async () => {
      const verifyEmailDto = { token: 'verification-token' };
      const expectedResponse = { message: 'Email verified successfully' };

      authService.verifyEmail.mockResolvedValue(expectedResponse);

      const result = await controller.verifyEmail(verifyEmailDto);

      expect(authService.verifyEmail).toHaveBeenCalledWith(verifyEmailDto.token);
      expect(result).toEqual(expectedResponse);
    });
  });

  describe('forgotPassword', () => {
    it('should request password reset', async () => {
      const forgotPasswordDto = { email: 'test@example.com' };
      const expectedResponse = { message: 'If the email exists, a password reset link has been sent' };

      authService.forgotPassword.mockResolvedValue(expectedResponse);

      const result = await controller.forgotPassword(forgotPasswordDto);

      expect(authService.forgotPassword).toHaveBeenCalledWith(forgotPasswordDto.email);
      expect(result).toEqual(expectedResponse);
    });
  });

  describe('resetPassword', () => {
    it('should reset password with token', async () => {
      const resetPasswordDto = {
        token: 'reset-token',
        newPassword: 'newpassword123',
      };
      const expectedResponse = { message: 'Password reset successfully' };

      authService.resetPassword.mockResolvedValue(expectedResponse);

      const result = await controller.resetPassword(resetPasswordDto);

      expect(authService.resetPassword).toHaveBeenCalledWith(
        resetPasswordDto.token,
        resetPasswordDto.newPassword,
      );
      expect(result).toEqual(expectedResponse);
    });
  });

  describe('resendVerification', () => {
    it('should resend email verification', async () => {
      const resendVerificationDto = { email: 'test@example.com' };
      const expectedResponse = { message: 'If the email exists, a verification email has been sent' };

      authService.resendVerificationEmail.mockResolvedValue(expectedResponse);

      const result = await controller.resendVerification(resendVerificationDto);

      expect(authService.resendVerificationEmail).toHaveBeenCalledWith(resendVerificationDto.email);
      expect(result).toEqual(expectedResponse);
    });
  });

  describe('googleAuth', () => {
    it('should initiate Google OAuth', async () => {
      const req = { user: mockUser };

      const result = await controller.googleAuth(req);

      expect(result).toBeUndefined();
    });
  });

  describe('googleAuthRedirect', () => {
    it('should handle Google OAuth callback', async () => {
      const req = { user: mockUser };
      const res = {
        redirect: jest.fn(),
      };

      process.env.FRONTEND_URL = 'http://localhost:3000';
      authService.googleLogin.mockResolvedValue(mockAuthResponse);

      await controller.googleAuthRedirect(req, res);

      expect(authService.googleLogin).toHaveBeenCalledWith(mockUser);
      expect(res.redirect).toHaveBeenCalledWith(
        `http://localhost:3000/auth/oauth-success?token=${mockAuthResponse.access_token}`,
      );
    });
  });
});
