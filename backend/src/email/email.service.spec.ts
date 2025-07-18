import { Test, TestingModule } from '@nestjs/testing';
import { MailerService } from '@nestjs-modules/mailer';
import { ConfigService } from '@nestjs/config';
import { EmailService } from './email.service';

describe('EmailService', () => {
  let service: EmailService;
  let mailerService: jest.Mocked<MailerService>;
  let configService: jest.Mocked<ConfigService>;

  beforeEach(async () => {
    const mockMailerService = {
      sendMail: jest.fn(),
    };

    const mockConfigService = {
      get: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EmailService,
        {
          provide: MailerService,
          useValue: mockMailerService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<EmailService>(EmailService);
    mailerService = module.get(MailerService);
    configService = module.get(ConfigService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('sendVerificationEmail', () => {
    it('should send verification email successfully', async () => {
      const email = 'test@example.com';
      const name = 'Test User';
      const token = 'verification-token';
      const frontendUrl = 'http://localhost:3000';

      configService.get.mockReturnValue(frontendUrl);
      mailerService.sendMail.mockResolvedValue(undefined);

      await service.sendVerificationEmail(email, name, token);

      expect(configService.get).toHaveBeenCalledWith('FRONTEND_URL');
      expect(mailerService.sendMail).toHaveBeenCalledWith({
        to: email,
        subject: 'Verify Your Email - GymForge',
        template: 'email-verification',
        context: {
          name,
          verificationUrl: `${frontendUrl}/auth/verify-email?token=${token}`,
          appName: 'GymForge',
        },
      });
    });

    it('should handle email sending errors', async () => {
      const email = 'test@example.com';
      const name = 'Test User';
      const token = 'verification-token';

      configService.get.mockReturnValue('http://localhost:3000');
      mailerService.sendMail.mockRejectedValue(new Error('Email service error'));

      await expect(service.sendVerificationEmail(email, name, token)).rejects.toThrow('Email service error');
    });
  });

  describe('sendPasswordResetEmail', () => {
    it('should send password reset email successfully', async () => {
      const email = 'test@example.com';
      const name = 'Test User';
      const token = 'reset-token';
      const frontendUrl = 'http://localhost:3000';

      configService.get.mockReturnValue(frontendUrl);
      mailerService.sendMail.mockResolvedValue(undefined);

      await service.sendPasswordResetEmail(email, name, token);

      expect(mailerService.sendMail).toHaveBeenCalledWith({
        to: email,
        subject: 'Reset Your Password - GymForge',
        template: 'password-reset',
        context: {
          name,
          resetUrl: `${frontendUrl}/auth/reset-password?token=${token}`,
          appName: 'GymForge',
        },
      });
    });
  });

  describe('sendWelcomeEmail', () => {
    it('should send welcome email successfully', async () => {
      const email = 'test@example.com';
      const name = 'Test User';
      const frontendUrl = 'http://localhost:3000';

      configService.get.mockReturnValue(frontendUrl);
      mailerService.sendMail.mockResolvedValue(undefined);

      await service.sendWelcomeEmail(email, name);

      expect(mailerService.sendMail).toHaveBeenCalledWith({
        to: email,
        subject: 'Welcome to GymForge!',
        template: 'welcome',
        context: {
          name,
          appName: 'GymForge',
          loginUrl: `${frontendUrl}/auth/login`,
        },
      });
    });
  });

  describe('sendPasswordChangedNotification', () => {
    it('should send password changed notification successfully', async () => {
      const email = 'test@example.com';
      const name = 'Test User';
      const supportEmail = 'support@gymforge.com';

      configService.get.mockReturnValue(supportEmail);
      mailerService.sendMail.mockResolvedValue(undefined);

      await service.sendPasswordChangedNotification(email, name);

      expect(mailerService.sendMail).toHaveBeenCalledWith({
        to: email,
        subject: 'Password Changed - GymForge',
        template: 'password-changed',
        context: {
          name,
          appName: 'GymForge',
          supportEmail,
        },
      });
    });
  });
});
