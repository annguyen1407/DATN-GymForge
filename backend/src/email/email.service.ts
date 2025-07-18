import { Injectable } from '@nestjs/common';
import { MailerService } from '@nestjs-modules/mailer';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EmailService {
  constructor(
    private readonly mailerService: MailerService,
    private readonly configService: ConfigService,
  ) {}

  async sendVerificationEmail(email: string, name: string, token: string): Promise<void> {
    const verificationUrl = `${this.configService.get('FRONTEND_URL')}/auth/verify-email?token=${token}`;
    
    await this.mailerService.sendMail({
      to: email,
      subject: 'Verify Your Email - GymForge',
      template: 'email-verification',
      context: {
        name,
        verificationUrl,
        appName: 'GymForge',
      },
    });
  }

  async sendPasswordResetEmail(email: string, name: string, token: string): Promise<void> {
    // Point to backend endpoint that will validate token and redirect to frontend form
    const resetUrl = `${this.configService.get('BACKEND_URL') || 'http://localhost:3000'}/auth/reset-password?token=${token}`;

    await this.mailerService.sendMail({
      to: email,
      subject: 'Reset Your Password - GymForge',
      template: 'password-reset',
      context: {
        name,
        resetUrl,
        appName: 'GymForge',
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
}
