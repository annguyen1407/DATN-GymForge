# API Surface (High-Level)
Generated: 2025-10-02

NOTE: This is a summarized map. For precise DTOs and validation rules, inspect each controller & service.

Cross References:
- Full catalog: `API_ENDPOINTS_FULL.md`
- Architecture overview: `ARCHITECTURE.md`
- Security review: `SECURITY_REVIEW.md`

## Conventions
- Auth: JWT required unless endpoint explicitly public (authentication controller may expose register/login).
- Role protection via `@Roles(...)` + `RolesGuard`.
- Standard CRUD pattern: POST (create), GET (list/detail), PATCH (partial update), DELETE (remove).

## Controllers & Routes
### /auth
- POST /register
- POST /login
- GET /profile (likely profile of authenticated user)
- GET /me (redundant? unify?)
- POST /verify-email
- POST /resend-verification
- POST /forgot-password
- POST /reset-password
- GET /google (OAuth redirect) /google/callback
- POST /refresh
- POST /logout
- PATCH /admin/users/:userId/soft-delete (ADMIN)
- PATCH /admin/users/:userId/restore (ADMIN)

### /equipment (ADMIN for mutations)
- POST /
- GET /
- GET /:id
- PATCH /:id
- DELETE /:id

### /exercises
- POST /
- GET / (list with filters?)
- GET /muscle-group/:muscleGroupId
- GET /:id
- PATCH /:id
- DELETE /:id
- GET /:id/performance/:userId
- GET /:id/performance/my (current user)

### /workout-plans
- POST /
- GET / (list maybe filters: user/template/visibility)
- GET /templates
- GET /templates/my
- PATCH /:id/template-status
- GET /user/:userId (plans of user)
- POST /clone-template/:templateId (suggest alt: POST /:templateId/clone)
- PATCH /:id
- DELETE /:id
- POST /:planId/days
- GET /:planId/days
- PATCH /days/:dayId
- DELETE /days/:dayId
- GET /days/:dayId/stats
- POST /exercises (attach exercise to plan/day) — (Consider nesting: /:planId/exercises)

### /exercise-logs
(Complex; includes CRUD for workout exercise logs & nested sets)
- Auth + Role restrictions (GYMER/COACH/ADMIN combos)
- Expect endpoints like create log, list logs, add set, update set, delete set, stats queries.

### /feedbacks
- POST / (GYMER)
- (Likely GET list, GET detail — not all grep’d due to partial scan)
- Admin + Gymer roles for moderation/deletion

### /training-requests
- Auth + layered role guards (coach vs gymer actions: create, accept, reject, cancel, quote pricing)
- Generates links to workout plans & training payments.

### /appointments
- Standard scheduling endpoints (create/list/update/cancel) tied to coach + gymer + optional workoutExercise link.

### /meals
- CRUD meal logs (GYMER | COACH). Suggest unify to user-specific filtering.

### /profile (user-profile)
- Likely GET/UPDATE personal profile info (not scanned in detail).

### /subscriptions
- Manage subscription plans, user subscription purchase/renewal + payment status.

### /salaries
- Coach salary aggregation & payout processing (ADMIN guarded expected).

### /muscle-groups
- Reference data (list, maybe create if admin) — not fully enumerated here.

### /admin-config
- GET / (fetch singleton)
- PATCH / (update config) (ADMIN expected)

## Cross-Cutting Concerns
- Pagination / filtering patterns not yet standardized in doc (add query param guidelines).
- Performance endpoints specialized (exercise performance) should unify naming: /performance vs /stats.

## Suggested Standardization
| Current | Suggested | Reason |
|---------|-----------|-------|
| /workout-plans/clone-template/:templateId | POST /workout-plans/:templateId/clone | Resource oriented |
| GET /auth/profile & GET /auth/me | Keep one (prefer /auth/me) | Reduce duplication |
| POST /workout-plans/exercises | POST /workout-plans/:planId/exercises | Scope clarity |
| :id/performance/:userId vs :id/performance/my | Use query `?userId=` or /performance (me) | Simplify route count |

## Potential Missing Endpoints (Check)
- Bulk set ordering for WorkoutExercise (if reorder UI exists)
- Soft delete for exercises/templates (instead of hard delete?)
- Metrics aggregation: weekly progress summary endpoint.

---
Security & Guards overview: see `SECURITY_REVIEW.md`.
Improvement backlog & actions: see `IMPROVEMENTS_BACKLOG.md`.
