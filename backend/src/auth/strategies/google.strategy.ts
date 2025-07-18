import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { ConfigService } from '@nestjs/config';
import { AuthService } from '../auth.service';
import { PrismaService } from '../../prisma/prisma.service';
import { UserRole } from '@prisma/client';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(
    private configService: ConfigService,
    private authService: AuthService,
    private prisma: PrismaService,
  ) {
    super({
      clientID: configService.get<string>('GOOGLE_CLIENT_ID')!,
      clientSecret: configService.get<string>('GOOGLE_CLIENT_SECRET')!,
      callbackURL: configService.get<string>('GOOGLE_CALLBACK_URL')!,
      scope: ['email', 'profile'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: any,
    done: VerifyCallback,
  ): Promise<any> {
    try {
      const { id, name, emails, photos } = profile;
      const email = emails[0].value;
      const firstName = name.givenName;
      const lastName = name.familyName;
      const picture = photos[0].value;

      // Check if user already exists with this Google ID
      let user = await this.prisma.user.findFirst({
        where: { googleId: id },
      });

      if (user) {
        // User exists with Google ID, return user
        return done(null, user);
      }

      // Check if user exists with this email
      user = await this.prisma.user.findUnique({
        where: { email },
      });

      if (user) {
        // User exists with email, link Google account
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: {
            googleId: id,
            profilePicture: picture,
            isEmailVerified: true, // Google emails are verified
          },
        });
        return done(null, user);
      }

      // Create new user
      user = await this.prisma.user.create({
        data: {
          email,
          googleId: id,
          name: `${firstName} ${lastName}`,
          profilePicture: picture,
          role: UserRole.GYMER,
          isEmailVerified: true, // Google emails are verified
        },
      });

      // Create gymer profile for new user
      await this.prisma.gymer.create({
        data: {
          userId: user.id,
        },
      });

      return done(null, user);
    } catch (error) {
      return done(error, false);
    }
  }
}
