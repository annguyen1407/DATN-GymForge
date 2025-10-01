import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ForbiddenException } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { TokenCacheService } from '../src/redis/token-cache.service';
import { EmailService } from '../src/email/email.service';
import { UserRole, TrainingRequestStatus, PlanType } from '@prisma/client';

const unique = (p: string) => `${p}.${Date.now()}${Math.floor(Math.random()*1000)}@test.dev`;
const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

const tokenCacheMock: Partial<TokenCacheService> = {
  storeRefreshToken: async () => {},
  getUserIdByRefreshToken: async () => null,
  removeRefreshToken: async () => {},
  removeAllUserRefreshTokens: async () => {},
};
const emailServiceMock: Partial<EmailService> = {
  sendVerificationOTP: async () => {},
  sendPasswordResetOTP: async () => {},
  sendWelcomeEmail: async () => {},
  sendPasswordChangedNotification: async () => {},
};

// Increase default Jest timeout for e2e
jest.setTimeout(120000);
process.env.PRISMA_CLIENT_ENGINE_TYPE = process.env.PRISMA_CLIENT_ENGINE_TYPE || 'binary';

describe('Workout Plan visibility by training status (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  let adminToken: string;
  let coachToken: string;
  let gymerToken: string;
  let coachUserId: string;
  let gymerUserId: string;
  let coachId: string;
  let gymerId: string;

  beforeAll(async () => {
    process.env.JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'test_access_secret';
    process.env.JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'test_refresh_secret';
    process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(TokenCacheService)
      .useValue(tokenCacheMock)
      .overrideProvider(EmailService)
      .useValue(emailServiceMock)
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get(PrismaService);

    // Create users
    const reg = async (email: string, role: UserRole) => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({ email, password: 'Passw0rd!', username: email.split('@')[0], name: email.split('@')[0], role })
        .expect(201);
      return res.body as { access_token: string; user: any };
    };

    const admin = await reg(unique('admin'), UserRole.ADMIN);
    adminToken = admin.access_token;

    const coach = await reg(unique('coach'), UserRole.COACH);
    coachToken = coach.access_token;
    coachUserId = coach.user.id;

    const gymer = await reg(unique('gymer'), UserRole.GYMER);
    gymerToken = gymer.access_token;
    gymerUserId = gymer.user.id;

    const coachProfile = await prisma.coach.findFirst({ where: { userId: coachUserId } });
    const gymerProfile = await prisma.gymer.findFirst({ where: { userId: gymerUserId } });
    coachId = coachProfile!.id;
    gymerId = gymerProfile!.id;

    // Ensure admin config exists
    await request(app.getHttpServer()).get('/admin-config').set(auth(adminToken)).expect(200);
  });

  afterAll(async () => {
    await app.close();
  });

  async function createAcceptedTraining(): Promise<string> {
    const tr = await request(app.getHttpServer())
      .post('/training-requests')
      .set(auth(gymerToken))
      .send({ gymerId, coachId })
      .expect(201);
    const trId = tr.body.id as string;

    const accepted = await request(app.getHttpServer())
      .post(`/training-requests/${trId}/accept`)
      .set(auth(coachToken))
      .expect(201);

    expect(accepted.body.status).toBe(TrainingRequestStatus.ACCEPTED);
    return trId;
  }

  it('gymer can view plan when training ACCEPTED; becomes hidden after cancel; admin/coach still can view', async () => {
    const trId = await createAcceptedTraining();

    // Coach creates a plan for gymer linked to training
    const createPlan = await request(app.getHttpServer())
      .post('/workout-plans')
      .set(auth(coachToken))
      .send({
        userId: gymerUserId,
        name: 'Plan A',
        planType: PlanType.STRENGTH,
        trainingRequestId: trId,
      })
      .expect(201);

    const planId = createPlan.body.id as string;

    // Visible to gymer while ACCEPTED
    await request(app.getHttpServer())
      .get(`/workout-plans/${planId}`)
      .set(auth(gymerToken))
      .expect(200);

    // Cancel training -> should hide for gymer
    await request(app.getHttpServer())
      .post(`/training-requests/${trId}/cancel`)
      .set(auth(gymerToken))
      .send({ reason: 'stop' })
      .expect(201);

    // Gymer now forbidden
    await request(app.getHttpServer())
      .get(`/workout-plans/${planId}`)
      .set(auth(gymerToken))
      .expect(403);

    // Admin can still view
    await request(app.getHttpServer())
      .get(`/workout-plans/${planId}`)
      .set(auth(adminToken))
      .expect(200);

    // Authoring coach can still view
    await request(app.getHttpServer())
      .get(`/workout-plans/${planId}`)
      .set(auth(coachToken))
      .expect(200);
  });

  it('visibility also enforced on listDays endpoint', async () => {
    const trId = await createAcceptedTraining();

    const plan = await request(app.getHttpServer())
      .post('/workout-plans')
      .set(auth(coachToken))
      .send({ userId: gymerUserId, name: 'Plan B', planType: PlanType.CARDIO, trainingRequestId: trId })
      .expect(201);

    const planId = plan.body.id as string;

    // Create a day
    await request(app.getHttpServer())
      .post(`/workout-plans/${planId}/days`)
      .set(auth(coachToken))
      .send({ dayNumber: 1 })
      .expect(201);

    // Visible while ACCEPTED
    await request(app.getHttpServer())
      .get(`/workout-plans/${planId}/days`)
      .set(auth(gymerToken))
      .expect(200);

    // Cancel training
    await request(app.getHttpServer())
      .post(`/training-requests/${trId}/cancel`)
      .set(auth(gymerToken))
      .send({ reason: 'stop' })
      .expect(201);

    // Now forbidden for gymer
    await request(app.getHttpServer())
      .get(`/workout-plans/${planId}/days`)
      .set(auth(gymerToken))
      .expect(403);
  });
});

