import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { TokenCacheService } from '../src/redis/token-cache.service';
import { EmailService } from '../src/email/email.service';
import { UserRole, PaymentStatus, TrainingRequestStatus } from '@prisma/client';

// Small helpers
const unique = (p: string) => `${p}.${Date.now()}${Math.floor(Math.random()*1000)}@test.dev`;
const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

// Simple no-op mocks to avoid external deps (Redis, SMTP)
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

describe('Training Requests + Payments (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  // Actors
  let adminToken: string;
  let coachToken: string;
  let gymerToken: string;
  let coachUserId: string;
  let gymerUserId: string;
  let coachId: string; // Coach profile id
  let gymerId: string; // Gymer profile id

  beforeAll(async () => {
    // Ensure JWT secrets exist for tests
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

    // Create admin, coach, gymer
    const adminEmail = unique('admin');
    const coachEmail = unique('coach');
    const gymerEmail = unique('gymer');

    const reg = async (email: string, role: UserRole) => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({ email, password: 'Passw0rd!', username: email.split('@')[0], name: email.split('@')[0], role })
        .expect(201);
      return res.body as { access_token: string; user: any };
    };

    const admin = await reg(adminEmail, UserRole.ADMIN);
    adminToken = admin.access_token;

    const coach = await reg(coachEmail, UserRole.COACH);
    coachToken = coach.access_token;
    coachUserId = coach.user.id;

    const gymer = await reg(gymerEmail, UserRole.GYMER);
    gymerToken = gymer.access_token;
    gymerUserId = gymer.user.id;

    // Look up profile ids
    const coachProfile = await prisma.coach.findFirst({ where: { userId: coachUserId } });
    const gymerProfile = await prisma.gymer.findFirst({ where: { userId: gymerUserId } });
    coachId = coachProfile!.id;
    gymerId = gymerProfile!.id;

    // Ensure admin config exists (auto-creates on GET)
    await request(app.getHttpServer())
      .get('/admin-config')
      .set(auth(adminToken))
      .expect(200);
  });

  afterAll(async () => {
    await app.close();
  });

  it('creates training request -> payment PENDING', async () => {
    const res = await request(app.getHttpServer())
      .post('/training-requests')
      .set(auth(gymerToken))
      .send({ gymerId, coachId })
      .expect(201);

    expect(res.body).toMatchObject({
      gymerId,
      coachId,
      status: TrainingRequestStatus.PENDING,
    });

    const trId = res.body.id;
    const payment = await prisma.trainingPayment.findFirst({ where: { trainingRequestId: trId } });
    expect(payment).toBeTruthy();
    expect(payment!.status).toBe(PaymentStatus.PENDING);
  });

  // Helper to create a fresh gymer for isolation per test
  async function createGymerActor() {
    const email = unique('gymer');
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email, password: 'Passw0rd!', username: email.split('@')[0], name: email.split('@')[0], role: UserRole.GYMER })
      .expect(201);
    const token = res.body.access_token as string;
    const userId = res.body.user.id as string;
    const prof = await prisma.gymer.findFirst({ where: { userId } });
    return { token, userId, gymerId: prof!.id };
  }

  it('accept flow: completes payment, creates earning, sets ACCEPTED', async () => {
    // Use a fresh gymer to avoid duplicate PENDING conflicts
    const g = await createGymerActor();

    const create = await request(app.getHttpServer())
      .post('/training-requests')
      .set(auth(g.token))
      .send({ gymerId: g.gymerId, coachId })
      .expect(201);

    const trId = create.body.id as string;

    const accept = await request(app.getHttpServer())
      .post(`/training-requests/${trId}/accept`)
      .set(auth(coachToken))
      .expect(201);

    expect(accept.body.status).toBe(TrainingRequestStatus.ACCEPTED);

    const payment = await prisma.trainingPayment.findFirst({ where: { trainingRequestId: trId } });
    expect(payment!.status).toBe(PaymentStatus.COMPLETED);

    const earning = await prisma.coachEarning.findFirst({ where: { trainingRequestId: trId } });
    expect(earning).toBeTruthy();
    expect(earning!.coachId).toBe(coachId);
  });

  it('reject flow: refunds payment, sets REJECTED', async () => {
    const g = await createGymerActor();

    const create = await request(app.getHttpServer())
      .post('/training-requests')
      .set(auth(g.token))
      .send({ gymerId: g.gymerId, coachId })
      .expect(201);

    const trId = create.body.id as string;

    const reject = await request(app.getHttpServer())
      .post(`/training-requests/${trId}/reject`)
      .set(auth(coachToken))
      .expect(201);

    expect(reject.body.status).toBe(TrainingRequestStatus.REJECTED);

    const payment = await prisma.trainingPayment.findFirst({ where: { trainingRequestId: trId } });
    expect(payment!.status).toBe(PaymentStatus.REFUNDED);

    const earning = await prisma.coachEarning.findFirst({ where: { trainingRequestId: trId } });
    expect(earning).toBeNull();
  });

  it('cancel flow: sets CANCELED without changing payment (still PENDING)', async () => {
    const g = await createGymerActor();

    const create = await request(app.getHttpServer())
      .post('/training-requests')
      .set(auth(g.token))
      .send({ gymerId: g.gymerId, coachId })
      .expect(201);

    const trId = create.body.id as string;

    // Cancel by gymer
    const cancel = await request(app.getHttpServer())
      .post(`/training-requests/${trId}/cancel`)
      .set(auth(g.token))
      .send({ reason: 'Change of plans' })
      .expect(201);

    expect(cancel.body.status).toBe(TrainingRequestStatus.CANCELED);

    const payment = await prisma.trainingPayment.findFirst({ where: { trainingRequestId: trId } });
    expect(payment!.status).toBe(PaymentStatus.PENDING);
  });
});

