# Security Review
Generated: 2025-10-02

## Authentication & Authorization
- JWT-based auth (JwtAuthGuard) applied to domain controllers.
- Role-based authorization via `@Roles` + `RolesGuard` on sensitive endpoints (ADMIN, COACH, GYMER splits).
- Public endpoints: register, login, email verification flows, OAuth redirect/callback (assumed). Recommend explicit `@Public()` metadata for clarity.

## Identified Risks & Mitigations
| Area | Risk | Current State | Recommendation |
|------|------|---------------|----------------|
| OTP Storage | Plaintext 6-digit OTP in DB | Exposed if DB leaked | Hash OTP (bcrypt / sha256 + secret pepper) + attempts counter |
| Monetary Precision | Floating point rounding errors | Float used for payments/commission | Migrate to Decimal in schema + format layer |
| Soft Deleted Users | Queries may include isDeleted users by mistake | Manual filtering required | Add Prisma middleware auto-appending `isDeleted=false` (except overrides) |
| Rate Limiting | Brute force login/OTP endpoints | No mention of throttle | Add Nest Throttler (e.g. 5/min login, 3/min OTP) |
| OAuth googleId | Potential collision / missing index | Field exists | Add unique index if used for login mapping |
| Password Reset OTP | Replay risk | OTP only + expiry | Invalidate on use + store hash + log attempt count |
| AdminConfig Update | Config tampering | Guarded by role? (assumed) | Ensure `@Roles(ADMIN)` + audit log per change |
| Logs & PII | Potential exposure in error responses | Not reviewed | Sanitize error messages; hide stack traces in prod |
| Exercise / Plan Deletion | Orphan analytics | Cascade defined | Provide soft delete if recoverability needed |

## Guard Strategy Improvements
1. Introduce a `Public` decorator + global auth guard that skips on metadata.
2. Layer composite guard: AuthGuard -> RolesGuard -> (Optional) OwnershipGuard (resource-level check: e.g., user modifying own plan).
3. Add `Scopes` concept if future granular permission needed.

## Token Lifecycle
- Refresh endpoint exists. Ensure:
  - Refresh tokens rotated & invalidated on logout.
  - Stored hashed in DB or cache (not raw) if persisted.

## Logging & Auditing
Recommended events to log (structured JSON):
- auth.login.success / auth.login.failure
- user.soft_delete / user.restore
- payment.training.captured / refunded / failed
- subscription.activated / expired / canceled
- admin.config.updated

## Transport & Headers
- Enforce HTTPS at proxy level.
- Add security headers (Helmet) if not already: CSP, X-Content-Type-Options, Referrer-Policy, etc.

## Input Validation
- Ensure DTOs use `class-validator` for all POST/PATCH data (lengths, enums, numeric ranges).
- Add explicit whitelist & forbidNonWhitelisted in global validation pipe.

## Data Exposure Minimization
- Avoid returning internal IDs for unrelated entities (e.g., trainingRequestId in public plan listing if not needed).
- For user objects: omit password, OTP fields, soft delete marker unless admin.

## Session & Concurrency Considerations
- Consider lock when processing coach salary generation to avoid double-run (distributed lock via Redis key).

## Next Steps (Prioritized)
1. OTP hashing + attempts limit.
2. Rate limiting for auth-sensitive endpoints.
3. Decimal migration for monetary fields.
4. Global soft delete filter for User.
5. Add audit logging layer (interceptor or service wrapper).

---
See `IMPROVEMENTS_BACKLOG.md` for actionable implementation tasks.
