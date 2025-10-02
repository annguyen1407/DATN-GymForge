# Migration: Remove ExerciseLog and attach SetsLog to WorkoutExerciseLog

This migration removes the legacy `ExerciseLog` model and connects `SetsLog` directly to `WorkoutExerciseLog`.

Why: `Exercise` is a static catalog. Historical `ExerciseLog` entries predated `WorkoutExercise`/`WorkoutExerciseLog` and created ambiguity. The system now logs sets per `WorkoutExerciseLog`.

## What changed

- Dropped `ExerciseLog` model
- `SetsLog` now references `WorkoutExerciseLog` via required `workoutExerciseLogId`
- All services and endpoints now use `WorkoutExerciseLog` + `SetsLog` directly
- New endpoint: `GET /exercise-logs/workout-exercise-logs/:id/sets`
- Backward-compatible endpoints:
  - `GET /exercise-logs/:id` -> returns `WorkoutExerciseLog`
  - `PATCH /exercise-logs/:id` -> updates WEL and replaces its sets (if provided)
  - `DELETE /exercise-logs/:id` -> deletes WEL (cascades sets)

## Safer option: backup-first + staged verification (recommended for data safety)

Use this when you might have legacy ExerciseLog data and want strict safety with a verified cutover.

1) Freeze writes (short maintenance window)
   - Put the app in maintenance mode or block write endpoints temporarily.

2) Full backup before any change
   - PostgreSQL example:
     - Logical backup (portable):
       - pg_dump --format=c --file=pre_wel_migration.dump --dbname "$DATABASE_URL"
     - Or full SQL (easier to inspect):
       - pg_dump --no-owner --no-privileges --file=pre_wel_migration.sql "$DATABASE_URL"

3) Create a staging database from the backup
   - createdb yourdb_staging
   - pg_restore --dbname=yourdb_staging pre_wel_migration.dump
   - Or psql yourdb_staging < pre_wel_migration.sql

4) Run the two migrations against staging
   - npx prisma migrate dev --name add-setslog-link-to-wel --url "$STAGING_DATABASE_URL"
   - Optional backfill on staging (only if you actually have ExerciseLog rows):
     - Export legacy rows for mapping and auditing:
       - psql "$STAGING_DATABASE_URL" -c "\\COPY (SELECT * FROM exercise_logs) TO 'exercise_logs_pre.csv' CSV HEADER"
       - psql "$STAGING_DATABASE_URL" -c "\\COPY (SELECT * FROM sets_logs WHERE \"exerciseLogId\" IS NOT NULL) TO 'sets_logs_pre.csv' CSV HEADER"
     - Run a custom backfill tailored to your schema. Two common patterns:
       - If exercise_logs already had workoutExerciseId per row, create one workout_exercise_log per exercise_log and set sets_logs.workoutExerciseLogId accordingly.
       - Otherwise, derive workoutExerciseId via your app’s domain rules (e.g., via a join path you know). Validate the mapping carefully.
     - Validate counts: number of sets with exerciseLogId not null should match number of sets migrated to a non-null workoutExerciseLogId.
   - Run the destructive migration afterwards only when validation is OK:
     - npx prisma migrate dev --name drop-exerciselog-and-require-setslog-wel --url "$STAGING_DATABASE_URL"

5) Verify on staging
   - Run smoke checks and domain queries (totals per day/month, a few known users) comparing pre-/post- stats using the CSVs.
   - Only when satisfied, proceed to production.

## Quick commands (frontend-friendly)

Run exactly in this order, from the backend folder (requires .env with DATABASE_URL set):

If Prisma shows a failed migration message, first run:
- npx prisma migrate resolve --rolled-back 20251001140227_drop_exerciselog_and_require_setslog_wel

1) Apply the first migration only (adds the nullable link)
- npx prisma db execute --file prisma/migrations/20251001140009_add_setslog_link_to_wel/migration.sql --schema prisma/schema.prisma
- npx prisma migrate resolve --applied 20251001140009_add_setslog_link_to_wel

2) Backfill legacy data (auto-detects columns and skips if nothing to do)
- npm run db:backfill:exerciselog-to-wel

3) Apply the destructive migration (drop ExerciseLog, require SetsLog->WEL)
- npx prisma db execute --file prisma/migrations/20251001140227_drop_exerciselog_and_require_setslog_wel/migration.sql --schema prisma/schema.prisma
- npx prisma migrate resolve --applied 20251001140227_drop_exerciselog_and_require_setslog_wel

4) Rebuild
- npm run build

If any step fails, stop and DM the backend dev. Do NOT proceed to the next step.


6) Apply to production
   - Repeat steps 2 and 4–5 on production (with a shorter maintenance window since you already rehearsed on staging).
   - If anything goes wrong, restore from pre_wel_migration.dump: createdb yourdb_restore && pg_restore --dbname=yourdb_restore pre_wel_migration.dump

