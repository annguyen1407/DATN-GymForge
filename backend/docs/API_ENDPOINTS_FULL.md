# Full API Endpoint Catalog
Generated: 2025-10-02

NOTE: Auto-derived from controller decorators. For payload shapes see corresponding DTO files.

## Legend
- M = Mutation (POST/PATCH/DELETE)
- R = Read (GET)
- Auth = Requires JWT (unless stated public)
- Roles shown if restricted by `@Roles`.

---
## Root
| Method | Path | Type | Roles | Notes |
|--------|------|------|-------|-------|
| GET | / | R | Public? | App health/root response |

## Authentication (/auth)
| Method | Path | Type | Roles | Notes |
|--------|------|------|-------|-------|
| POST | /auth/register | M | Public | Register new user (creates profile) |
| POST | /auth/login | M | Public | Issue access + refresh tokens |
| GET | /auth/profile | R | Auth | Returns current user entity |
| GET | /auth/me | R | Auth | Returns fresh user record (difference vs profile) |
| POST | /auth/verify-email | M | Public (OTP) | Verify email with OTP |
| POST | /auth/resend-verification | M | Public | Resend verification OTP |
| POST | /auth/forgot-password | M | Public | Request password reset OTP |
| POST | /auth/reset-password | M | Public | Reset password with OTP |
| GET | /auth/google | R | Public | Initiate Google OAuth |
| GET | /auth/google/callback | R | Public | OAuth callback, redirects with token |
| POST | /auth/refresh | M | Public (refresh token required) | Token rotation |
| POST | /auth/logout | M | Auth | Invalidate refresh token |
| PATCH | /auth/admin/users/:userId/soft-delete | M | ADMIN | Soft delete user |
| PATCH | /auth/admin/users/:userId/restore | M | ADMIN | Restore user |

## Coaches (/coaches)
| Method | Path | Type | Roles | Notes |
| POST | /coaches | M | Auth | Create coach profile? (Redundant if auto) |
| GET | /coaches | R | Auth | List coaches (filters in service) |
| GET | /coaches/:id | R | Auth | Coach detail |
| GET | /coaches/user/:userId | R | Auth | Coach by userId |
| PATCH | /coaches/:id | M | Auth | Update coach |
| PATCH | /coaches/me/open-to-training | M | COACH | Toggle availability |
| PATCH | /coaches/:id/approve | M | ADMIN | Approve coach account |
| DELETE | /coaches/:id | M | ADMIN | Remove coach |

## Gymers (/gymers)
| Method | Path | Type | Roles | Notes |
| POST | /gymers | M | Auth | Create gymer profile? |
| GET | /gymers | R | Auth | List gymers |
| GET | /gymers/:id | R | Auth | Detail |
| GET | /gymers/user/:userId | R | Auth | By userId |
| PATCH | /gymers/:id | M | Auth | Update gymer |
| DELETE | /gymers/:id | M | ADMIN? | Confirm role check in service |

## Equipment (/equipment)
| Method | Path | Type | Roles | Notes |
| POST | /equipment | M | ADMIN | Create equipment |
| GET | /equipment | R | Auth | List equipment |
| GET | /equipment/:id | R | Auth | Detail |
| PATCH | /equipment/:id | M | ADMIN | Update |
| DELETE | /equipment/:id | M | ADMIN | Delete |

## Muscle Groups (/muscle-groups)
| Method | Path | Type | Roles | Notes |
| POST | /muscle-groups | M | Auth (prob ADMIN) | Create |
| GET | /muscle-groups | R | Auth | List |
| GET | /muscle-groups/:id | R | Auth | Detail |
| PATCH | /muscle-groups/:id | M | Auth | Update |
| DELETE | /muscle-groups/:id | M | Auth | Delete |

## Exercises (/exercises)
| Method | Path | Type | Roles | Notes |
| POST | /exercises | M | Auth | Create exercise |
| GET | /exercises | R | Auth | List (search/filter) |
| GET | /exercises/muscle-group/:muscleGroupId | R | Auth | Filter by muscle group |
| GET | /exercises/:id | R | Auth | Detail |
| PATCH | /exercises/:id | M | Auth | Update |
| DELETE | /exercises/:id | M | Auth | Delete |
| GET | /exercises/:id/performance/:userId | R | Auth | Performance for userId |
| GET | /exercises/:id/performance/my | R | Auth | Performance for current user |

## Workout Plans (/workout-plans)
| Method | Path | Type | Roles | Notes |
| POST | /workout-plans | M | (ALL roles) | Create plan |
| GET | /workout-plans | R | Auth | List (optionally filter by userId) |
| GET | /workout-plans/templates | R | Auth | List templates |
| GET | /workout-plans/templates/my | R | COACH/ADMIN | Templates created by me |
| PATCH | /workout-plans/:id/template-status | M | COACH/ADMIN | Toggle template flag |
| GET | /workout-plans/user/:userId | R | Auth | Plans by userId |
| POST | /workout-plans/clone-template/:templateId | M | (ALL roles) | Clone template (naming to refactor) |
| PATCH | /workout-plans/:id | M | (ALL roles) | Update plan |
| DELETE | /workout-plans/:id | M | (ALL roles) | Delete plan |
| POST | /workout-plans/:planId/days | M | (ALL roles) | Create day |
| GET | /workout-plans/:planId/days | R | Auth | List days |
| PATCH | /workout-plans/days/:dayId | M | (ALL roles) | Update day |
| DELETE | /workout-plans/days/:dayId | M | (ALL roles) | Delete day |
| GET | /workout-plans/days/:dayId/stats | R | Auth | Day stats |
| POST | /workout-plans/exercises | M | (ALL roles) | Add exercise to plan/day |
| DELETE | /workout-plans/exercises/:exerciseId | M | (ALL roles) | Remove workout exercise |
| PATCH | /workout-plans/exercises/:exerciseId | M | (ALL roles) | Update workout exercise |
| GET | /workout-plans/exercises/:workoutExerciseId/logs | R | Auth | Logs for one |
| GET | /workout-plans/exercises | R | Auth | List workout exercises (filters) |
| GET | /workout-plans/:id | R | Auth | Plan detail |

## Exercise Logs (/exercise-logs)
(Statistics & logging layer)
| Method | Path | Type | Roles | Notes |
| POST | /exercise-logs | M | GYMER/COACH | Create log (detailed) |
| POST | /exercise-logs/quick-log | M | GYMER/COACH | Quick log (with sets) |
| GET | /exercise-logs/user/:userId | R | GYMER/COACH/ADMIN | User logs |
| GET | /exercise-logs/my-logs | R | GYMER/COACH | Current user logs |
| GET | /exercise-logs/stats/daily/my/:date | R | GYMER/COACH | Daily stats (me) |
| GET | /exercise-logs/stats/daily/:userId/:date | R | GYMER/COACH/ADMIN | Daily stats (user) |
| GET | /exercise-logs/stats/weekly/my/:weekStart | R | GYMER/COACH | Weekly stats (me) |
| GET | /exercise-logs/stats/weekly/:userId/:weekStart | R | GYMER/COACH/ADMIN | Weekly stats (user) |
| GET | /exercise-logs/stats/monthly/my/:month | R | GYMER/COACH | Monthly stats (me) |
| GET | /exercise-logs/stats/monthly/:userId/:month | R | GYMER/COACH/ADMIN | Monthly stats (user) |
| GET | /exercise-logs/workout-plan-progress/my/:workoutPlanId | R | GYMER/COACH | Plan progress (me) |
| GET | /exercise-logs/workout-plan-progress/:userId/:workoutPlanId | R | GYMER/COACH/ADMIN | Plan progress (user) |
| GET | /exercise-logs/workout-plans-progress/my | R | GYMER/COACH | All plan progress (me) |
| GET | /exercise-logs/workout-plans-progress/:userId | R | GYMER/COACH/ADMIN | All plan progress (user) |
| GET | /exercise-logs/performance/my | R | GYMER/COACH | Performance list (me) |
| GET | /exercise-logs/performance/:userId | R | GYMER/COACH/ADMIN | Performance list (user) |
| GET | /exercise-logs/streaks/my | R | GYMER/COACH | Streaks (me) |
| GET | /exercise-logs/streaks/:userId | R | GYMER/COACH/ADMIN | Streaks (user) |
| GET | /exercise-logs/workout-exercise-logs/:id/sets | R | GYMER/COACH/ADMIN | Set list for a log |
| POST | /exercise-logs/logs/my/:date | M | GYMER/COACH | Upsert daily log |
| GET | /exercise-logs/logs/my/:date | R | GYMER/COACH | Get daily log |
| PATCH | /exercise-logs/logs/my/:date | M | GYMER/COACH | Update daily log |
| DELETE | /exercise-logs/logs/my/:date | M | GYMER/COACH | Delete daily log |
| GET | /exercise-logs/:id | R | GYMER/COACH/ADMIN | WorkoutExerciseLog detail (legacy alias) |
| PATCH | /exercise-logs/:id | M | GYMER/COACH | Update WorkoutExerciseLog |
| DELETE | /exercise-logs/:id | M | GYMER/COACH/ADMIN | Delete WorkoutExerciseLog |

## Training Requests (/training-requests)
| Method | Path | Type | Roles | Notes |
| POST | /training-requests | M | COACH/GYMER | Create request |
| GET | /training-requests | R | Auth | Filter: gymerId/coachId/status |
| GET | /training-requests/:id | R | Auth | Detail |
| PATCH | /training-requests/:id | M | ADMIN/COACH/GYMER | Update (generic) |
| DELETE | /training-requests/:id | M | ADMIN/COACH/GYMER | Delete |
| POST | /training-requests/:id/accept | M | ADMIN/COACH | Accept |
| POST | /training-requests/:id/reject | M | ADMIN/COACH | Reject |
| POST | /training-requests/:id/cancel | M | ADMIN/COACH/GYMER | Cancel with reason |

## Appointments (/appointments)
| Method | Path | Type | Roles | Notes |
| POST | /appointments | M | Auth | Create appointment |
| GET | /appointments | R | Auth | List (filters likely) |
| GET | /appointments/upcoming | R | Auth | Upcoming subset |
| GET | /appointments/:id | R | Auth | Detail |
| PATCH | /appointments/:id | M | Auth | Update |
| DELETE | /appointments/:id | M | Auth | Cancel/Delete |

## Meals (/meals)
| Method | Path | Type | Roles | Notes |
| POST | /meals/day/my/:date | M | GYMER/COACH | Add meal for date |
| GET | /meals/my/:date | R | GYMER/COACH | Meals for date |
| DELETE | /meals/day/my/:date/:mealId | M | GYMER/COACH | Remove meal |
| PATCH | /meals/day/my/:date/:mealId | M | GYMER/COACH | Update meal |
| GET | /meals/daily-intake/my/:date | R | GYMER/COACH | Totals for date |
| GET | /meals/my/:date/meal-type/:type/summary | R | GYMER/COACH | By meal type summary |
| GET | /meals/my/:date/summary | R | GYMER/COACH | Overall summary |

## Feedbacks (/feedbacks)
| Method | Path | Type | Roles | Notes |
| POST | /feedbacks | M | GYMER | Create feedback |
| GET | /feedbacks | R | Auth | List |
| GET | /feedbacks/coach/:coachId | R | Auth | Feedback for coach |
| GET | /feedbacks/coach/:coachId/stats | R | Auth | Coach rating stats |
| GET | /feedbacks/:id | R | Auth | Detail |
| PATCH | /feedbacks/:id | M | ADMIN/GYMER | Update (owner or admin) |
| DELETE | /feedbacks/:id | M | ADMIN/GYMER | Delete |

## User Profile (/profile)
| Method | Path | Type | Roles | Notes |
| POST | /profile | M | Auth | Create profile data (if separate) |
| PATCH | /profile | M | Auth | Update |
| GET | /profile | R | Auth | Current profile |
| DELETE | /profile/:userId | M | ADMIN? | Remove profile (check role guard) |

## Subscriptions (/subscriptions)
| Method | Path | Type | Roles | Notes |
| GET | /subscriptions/plans | R | Auth | List subscription plans |
| GET | /subscriptions/status | R | Auth | Current user subscription status |
| POST | /subscriptions/purchase | M | Auth | Purchase plan |
| POST | /subscriptions/plans | M | ADMIN | Create plan |
| POST | /subscriptions/plans/update | M | ADMIN | Update plan (non-REST naming; consider PATCH /subscriptions/plans/:id) |

## Salaries (/salaries)
| Method | Path | Type | Roles | Notes |
| GET | /salaries/my-earnings | R | COACH/ADMIN | Coach earnings summary (admin can query coachId) |
| GET | /salaries/monthly | R | COACH/ADMIN | Monthly salary (self or target coachId if admin) |
| POST | /salaries/:salaryId/mark-paid | M | ADMIN | Mark salary paid |

## Admin Config (/admin-config)
| Method | Path | Type | Roles | Notes |
| GET | /admin-config | R | ADMIN | Fetch config singleton |
| PUT | /admin-config | M | ADMIN | Update config singleton |

## User Profile vs User Entity
User modifications (soft delete / restore) are via `/auth/admin/users/...` while additional profile attributes done via `/profile`.

---
## Observations
- Some endpoints could be normalized (e.g., `/workout-plans/clone-template/:templateId`, `/subscriptions/plans/update`).
- Duplicate semantics: `/auth/profile` vs `/auth/me`.
- Role annotations absent in some controllers (assumed enforced at service level). Consider consistent explicit Roles.

## Next Steps (If Acting on This Catalog)
1. Introduce naming uniformity (clone/plan updates).
2. Add `@Public()` metadata for true public routes; global auth guard for rest.
3. Consider versioning path prefix `/v1` before expansion.

---
Cross-reference high-level map: `API_SURFACE.md`
Architecture details: `ARCHITECTURE.md` (to be created).
