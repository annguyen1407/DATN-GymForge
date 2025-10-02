# Schema Overview

Generated: 2025-10-02

## Enums
- UserRole: ADMIN | COACH | GYMER
- Gender: MALE | FEMALE | OTHER
- TrainingRequestStatus: PENDING | ACCEPTED | REJECTED | CANCELED
- AppointmentStatus: PENDING | CONFIRMED | COMPLETED | CANCELED
- PaymentStatus: PENDING | COMPLETED | FAILED | REFUNDED
- PaymentMethod: CASH | BANK_TRANSFER | CREDIT_CARD | MOMO | VNPAY | APPLE_IAP
- MealType: BREAKFAST | LUNCH | DINNER | SNACK
- PlanType: STRENGTH | CARDIO | FLEXIBILITY | COMBINED
- PlanStatus: ACTIVE | INACTIVE | COMPLETED
- DayStatus: PENDING | COMPLETED | SKIPPED
- FitnessGoal: LOSE_WEIGHT | BUILD_MUSCLE | BULKING | CUTTING | STRENGTH_TRAINING | ENDURANCE | GENERAL_FITNESS | FLEXIBILITY | WEIGHT_MAINTENANCE | ATHLETIC_PERFORMANCE
- SalaryStatus: DUE | PAID
- SubscriptionStatus: ACTIVE | EXPIRED | CANCELED

## Core Domain Models
### User
Auth + profile + progression. Soft delete via `isDeleted`. Premium flags & expiration. OTP fields for email & password reset (currently plaintext). 1:1 Coach (UserCoach) & Gymer (UserGymer).

### Coach / Gymer
Derived identities. Coach has rating metrics, training price. Gymer has training requests received.

### TrainingRequest
Connects a gymer and coach. Supports pricing, scheduling, cancellation window, and links to generated WorkoutPlans + TrainingPayment.

### WorkoutPlan / WorkoutDay / WorkoutExercise
Hierarchical plan structure. `WorkoutPlan` can be template and/or premium Only. Day status (PENDING/COMPLETED/SKIPPED). Exercises contain target metrics & ordering.

### Exercise & MuscleGroup
Many-to-many via `ExerciseMuscleGroup`. Stores default parameters (sets, reps, weight, rest) and optional MET value.

### Logging Layer
- `Log`: daily entry (biometrics + calories)
- `WorkoutExerciseLog`: execution instance of a planned exercise (progressPercent snapshot, totalTime, calories)
- `SetsLog`: per set detail (currently lacks timestamps)
- `Meal`: caloric intake records

### Payments & Earnings
Separated flows for training (TrainingPayment + CoachEarning + CoachSalary) and subscriptions (SubscriptionPlan + UserSubscription + SubscriptionPayment). Commission + salary aggregation tracked.

### Other
- `AdminConfig`: singleton operational tunables.
- `Notification`, `Achievement`, `Feedback`, `Appointment`, `Conversation`, `Message`.

## Relationships (Selected)
- User (1) — (1) Coach, Gymer
- Coach (1) — (m) TrainingRequests (sent)
- Gymer (1) — (m) TrainingRequests (received)
- TrainingRequest (1) — (1) TrainingPayment
- WorkoutPlan (1) — (m) WorkoutDay — (m) WorkoutExercise
- WorkoutExercise (1) — (m) WorkoutExerciseLog — (m) SetsLog
- Log (1) — (m) WorkoutExerciseLog; Log (1) — (m) Meal
- User (1) — (m) Payments / Subscriptions / Achievements / Notifications / Messages

## Indexing Highlights
- Frequent filters: status, createdAt, foreign keys, isTemplate, isPremiumOnly.
- Composite: (workoutDayId, order) for ordered exercises.
- Potential Additions:
  - (userId, createdAt) on `logs` for ordered pagination.
  - Partial index WHERE isDeleted=false on users (Postgres) for active queries.
  - Index on `WorkoutExerciseLog(dayNumber)` if analytics per day is heavy.

## Data Integrity Notes
- Financial floats (amount, commission) risk precision → suggest Decimal.
- OTP fields stored plaintext → suggest hashing + attempts counter.
- `SetsLog` missing timestamps → add `createdAt` if order needed.
- Multiple null `email` / `username` allowed due to nullable + unique (Postgres behavior). Ensure auth logic handles.

## Soft Delete Strategy
Only `User` has soft delete markers. Downstream queries must exclude `isDeleted=true` or add Prisma middleware.

## Denormalization Choices
- `progressPercent` stored (could be derived) for analytic speed.
- Commission / aggregated salary fields maintained—ensure transactional updates.

## Suggested Immediate Enhancements
1. Convert monetary floats -> Decimal
2. Add timestamps to `SetsLog`
3. Hash OTP values
4. Add partial index for active users
5. Implement Prisma middleware for soft delete filtering

---
For full API mapping see `API_SURFACE.md`. Security posture in `SECURITY_REVIEW.md`.
