import { Injectable } from '@nestjs/common';
import { MailerService } from '@nestjs-modules/mailer';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EmailService {
  constructor(
    private readonly mailerService: MailerService,
    private readonly configService: ConfigService,
  ) {}

  async sendVerificationOTP(email: string, name: string, otp: string): Promise<void> {
    await this.mailerService.sendMail({
      to: email,
      subject: 'Verify Your Email - GymForge',
      template: 'email-verification-otp',
      context: {
        name,
        otp,
        appName: 'GymForge',
        expiresInMinutes: 10, // OTP expires in 10 minutes
      },
    });
  }

  async sendPasswordResetOTP(email: string, name: string, otp: string): Promise<void> {
    await this.mailerService.sendMail({
      to: email,
      subject: 'Reset Your Password - GymForge',
      template: 'password-reset-otp',
      context: {
        name,
        otp,
        appName: 'GymForge',
        expiresInMinutes: 10, // OTP expires in 10 minutes
      },
    });
  }

  async sendWelcomeEmail(email: string, name: string): Promise<void> {
    await this.mailerService.sendMail({
      to: email,
      subject: 'Welcome to GymForge!',
      template: 'welcome',
      context: {
        name,
        appName: 'GymForge',
        loginUrl: `${this.configService.get('FRONTEND_URL')}/auth/login`,
      },
    });
  }

  async sendPasswordChangedNotification(email: string, name: string): Promise<void> {
    await this.mailerService.sendMail({
      to: email,
      subject: 'Password Changed - GymForge',
      template: 'password-changed',
      context: {
        name,
        appName: 'GymForge',
        supportEmail: this.configService.get('SUPPORT_EMAIL'),
      },
    });
  }

  async sendCoachApprovedNotification(email: string, name: string): Promise<void> {
    await this.mailerService.sendMail({
      to: email,
      subject: 'Your Coach Account Has Been Approved - GymForge',
      template: 'coach-approved',
      context: {
        name,
        appName: 'GymForge',
        dashboardUrl: `${this.configService.get('FRONTEND_URL')}/coach/dashboard`,
      },
    });
  }

}
