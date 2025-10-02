# Architecture Overview
Generated: 2025-10-02

## Layering
Application follows NestJS modular structure:
- Entry: `main.ts` (bootstrap, CORS, global pipes, Swagger)
- Root Module: `AppModule` wires feature modules
- Feature Modules: auth, workout-plans, exercise-logs, training-requests, subscriptions, salaries, admin-config, etc.
- Cross-Cutting: PrismaModule (DB), EmailModule, Redis (token cache)

## Request Lifecycle (Typical Authenticated Request)
1. HTTP Request hits controller route
2. Global middlewares (none custom yet) & CORS
3. Guards:
   - `JwtAuthGuard` validates token -> attaches user payload
   - `RolesGuard` (if present) checks `@Roles()` metadata
4. Validation Pipe transforms & validates body/query/params (DTO) (whitelist + forbid extraneous fields)
5. Controller method delegates to Service
6. Service uses `PrismaService` (direct ORM) + other helpers (EmailService, TokenCacheService)
7. Response serialized (no custom interceptors currently) and returned

## Data Access Strategy
- Direct Prisma Client usage inside services (no repository abstraction). Simpler layering, acceptable for medium project.
- Logging enabled for all queries (can be verbose in prod). Consider conditional logs by env.

## Domain Boundaries
| Domain | Purpose | Key Entities | Interactions |
|--------|---------|--------------|-------------|
| Auth | Identity, tokens, OTP, soft delete | User | EmailService, Redis Token Cache |
| Workout Plans | Programming template + schedule | WorkoutPlan/Day/Exercise | Exercise Logs for progress |
| Exercise Logs | Execution + analytics | WorkoutExerciseLog, SetsLog, Log | References WorkoutExercise & Plan structure |
| Training Requests | Coach–Gymer contract negotiation | TrainingRequest | Generates WorkoutPlans & Payments |
| Subscriptions | Premium access monetization | SubscriptionPlan, UserSubscription | Affects premium-only plan visibility |
| Salaries | Coach earnings aggregation | CoachEarning, CoachSalary | Depends on TrainingPayment / commission config |
| Admin Config | System tunables (pricing multipliers) | AdminConfig | Read by pricing calculators |
| Feedback / Ratings | Quality & trust signals | Feedback | Influences coach averageRating |
| Meals / Nutrition | Caloric intake tracking | Meal, Log | Combines with exercise burn for net stats |

## Authentication & Authorization
- JWT Access (short-lived) + Refresh (7d) stored in Redis keyed per token.
- Refresh rotation enforced (old token removed upon refresh).
- Soft delete: user flagged; refresh tokens purged.
- Email verification & password reset via OTP (plaintext currently) -> queued improvement.

## Logging & Metrics
- Prisma query logs on by default.
- No structured audit layer yet (recommended for payments, salary payouts, admin config changes).

## Error Handling
- Relies on Nest standard HTTP exceptions (Conflict, Unauthorized, NotFound, BadRequest).
- Suggest global exception filter for consistent JSON envelope `{ error: { code, message } }`.

## Performance Considerations
- Index coverage strong (status, foreign keys, composite order indexes).
- Denormalized progressPercent on workout exercise logs speeds read.
- Potential caching candidates: `subscription_plans`, `muscle_groups`, `equipment`.

## Security Considerations (Summary)
See `SECURITY_REVIEW.md`, highlights:
- OTP hashing pending
- Rate limiting not applied yet
- Monetary precision migration recommended
- Soft delete filtering middleware proposal

## Extensibility
Future modules that can slot in cleanly:
- Notifications real-time gateway (WebSocket Module)
- Leaderboards / Social sharing module
- Analytics export module

## Suggested Immediate Technical Enhancements
1. Add `@Public()` decorator + global auth guard for clarity
2. Introduce AuditInterceptor (logs: route, userId, entity, action)
3. Add OwnershipGuard for resources keyed by userId/coachId to reduce service-level duplication
4. Extract pricing logic (training + subscription) into dedicated PricingService referencing AdminConfig
5. Introduce EventEmitter or CQRS for side effects: (plan cloned, request accepted, subscription activated)

## Dependency Overview
- bcryptjs for password hashing
- @nestjs/swagger integrated already
- Redis via custom token cache service (likely ioredis or node-redis under the hood—verify implementation file)

## Directory Highlights
- `src/prisma` holds service wiring; schema in root `prisma/` (migrations + models)
- `src/redis/token-cache.service.ts` manages refresh token storage (TTL)
- `src/email/templates` keeps transactional emails (OTP, welcome, etc.)
- DTO segregation per module ensures explicit interfaces

## Known Gaps / Risks
| Gap | Impact | Mitigation |
|-----|--------|-----------|
| Duplicate auth endpoints (`/profile` vs `/me`) | Confusion | Deprecate one |
| OTP plaintext | Account takeover risk if DB leak | Hash + attempt counter |
| Lack of global error envelope | Inconsistent FE handling | Add GlobalExceptionFilter |
| Mixed route naming patterns | Learning curve higher | Normalize (clone, update endpoints) |
| No versioning | Harder future breaking changes | Introduce /v1 prefix early |

## Request Example (Exercise Quick Log)
1. Client POST /exercise-logs/quick-log (JWT)
2. JwtAuthGuard attaches user
3. RolesGuard ensures role ∈ {GYMER, COACH}
4. ValidationPipe validates QuickLogExerciseDto
5. Service: ensures workoutExercise exists, creates log + sets, computes progressPercent
6. Returns structured log entity with nested sets summary

---
For exhaustive endpoints: `API_ENDPOINTS_FULL.md`
For security-specific notes: `SECURITY_REVIEW.md`
For improvement pipeline: `IMPROVEMENTS_BACKLOG.md`
