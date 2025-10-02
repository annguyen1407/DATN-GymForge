import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function tableExists(table: string): Promise<boolean> {
  const res = await prisma.$queryRawUnsafe<any[]>(
    `SELECT to_regclass('public."${table}"') IS NOT NULL AS exists;`
  );
  return !!res?.[0]?.exists;
}

async function columnExists(table: string, column: string): Promise<boolean> {
  const res = await prisma.$queryRawUnsafe<any[]>(
    `SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='${table}' AND column_name='${column}' LIMIT 1;`
  );
  return res.length > 0;
}

async function getColumns(table: string): Promise<Set<string>> {
  const rows = await prisma.$queryRawUnsafe<any[]>(
    `SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='${table}';`
  );
  return new Set(rows.map(r => r.column_name));
}

function pickCol(cols: Set<string>, ...candidates: string[]): string | null {
  for (const c of candidates) {
    if (cols.has(c)) return `"${c}"`;
  }
  return null;
}

(async () => {
  console.log('[backfill] Start backfill ExerciseLog -> WorkoutExerciseLog');
  try {
    const hasExerciseLogs = await tableExists('exercise_logs');
    const hasSetsLogs = await tableExists('sets_logs');

    if (!hasSetsLogs) {
      console.log('[backfill] sets_logs table not found. Nothing to do.');
      return;
    }

    const hasSetsExerciseLogId = await columnExists('sets_logs', 'exerciseLogId');
    if (!hasExerciseLogs || !hasSetsExerciseLogId) {
      console.log('[backfill] No legacy exercise_logs or sets_logs.exerciseLogId column. Nothing to migrate.');
      return;
    }

    const elCols = await getColumns('exercise_logs');
    const logIdCol = pickCol(elCols, 'workoutLogId', 'logId', 'workout_log_id', 'log_id');
    const weCol = pickCol(elCols, 'workoutExerciseId', 'workout_exercise_id');
    const dateCol = pickCol(elCols, 'date', 'dateLogged', 'date_logged');
    const progressCol = pickCol(elCols, 'progressPercent');
    const caloCol = pickCol(elCols, 'calo_burned', 'caloriesBurned');
    const dayCol = pickCol(elCols, 'dayNumber');
    const totalTimeCol = pickCol(elCols, 'totalTime');

    if (!logIdCol) {
      console.error('[backfill] Required columns missing on exercise_logs. Need workoutLogId/logId (or snake_case). Aborting.');
      process.exitCode = 1;
      return;
    }

    console.log('[backfill] Using column mapping:', { logIdCol, weCol, dateCol, progressCol, caloCol, dayCol, totalTimeCol });

    // 1) Insert missing WorkoutExerciseLog rows inferred from exercise_logs (only if we have enough columns)
    const canInsertWel = Boolean(weCol && dateCol);
    const insertWelSQL = canInsertWel ? `
      INSERT INTO "workout_exercise_logs" ("logId","workoutExerciseId","date","progressPercent","calo_burned","dayNumber","totalTime")
      SELECT el.${logIdCol}, el.${weCol}, el.${dateCol},
             ${progressCol ?? 'NULL'},
             ${caloCol ?? 'NULL'},
             ${dayCol ?? 'NULL'},
             COALESCE(${totalTimeCol ?? 'NULL'}, 0)
      FROM "exercise_logs" el
      LEFT JOIN "workout_exercise_logs" wel
        ON wel."logId" = el.${logIdCol}
       AND wel."workoutExerciseId" = el.${weCol}
       AND wel."date" = el.${dateCol}
      WHERE wel.id IS NULL;
    ` : null;

    // 2) Update sets_logs to point at the newly created/matched WEL, based on the same join key (only if we have enough columns)
    const updateSetsSQL = canInsertWel ? `
      UPDATE "sets_logs" s
      SET "workoutExerciseLogId" = wel.id
      FROM "workout_exercise_logs" wel
      JOIN "exercise_logs" el ON el.id = s."exerciseLogId"
      WHERE wel."logId" = el.${logIdCol}
        AND wel."workoutExerciseId" = el.${weCol}
        AND wel."date" = el.${dateCol}
        AND (s."workoutExerciseLogId" IS NULL OR s."workoutExerciseLogId" <> wel.id);
    ` : null;

    // 3) Recompute WEL.totalTime from sets_logs (sum of times)
    const recomputeWelTimeSQL = `
      UPDATE "workout_exercise_logs" w
      SET "totalTime" = sub.sum_times
      FROM (
        SELECT s."workoutExerciseLogId" AS id, COALESCE(SUM(s.times), 0) AS sum_times
        FROM "sets_logs" s
        WHERE s."workoutExerciseLogId" IS NOT NULL
        GROUP BY s."workoutExerciseLogId"
      ) sub
      WHERE w.id = sub.id;
    `;

    // 4) Recompute logs.totalWorkoutTime as sum of WEL.totalTime per log
    const recomputeLogTimeSQL = `
      UPDATE "logs" l
      SET "totalWorkoutTime" = COALESCE(sub.sum_time, 0)
      FROM (
        SELECT wel."logId" AS log_id, SUM(COALESCE(wel."totalTime", 0)) AS sum_time
        FROM "workout_exercise_logs" wel
        GROUP BY wel."logId"
      ) sub
      WHERE l.id = sub.log_id;
    `;

    // BEGIN transaction
    await prisma.$executeRawUnsafe('BEGIN');

    const beforeCounts = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
         (SELECT COUNT(*) FROM "exercise_logs") AS exercise_logs,
         (SELECT COUNT(*) FROM "workout_exercise_logs") AS workout_exercise_logs,
         (SELECT COUNT(*) FROM "sets_logs" WHERE "exerciseLogId" IS NOT NULL) AS sets_with_exerciseLogId,
         (SELECT COUNT(*) FROM "sets_logs" WHERE "workoutExerciseLogId" IS NOT NULL) AS sets_with_wel
       ;`
    );
    console.log('[backfill] Before:', beforeCounts?.[0]);

    // Deterministic mapping by (logId, workoutExerciseId, date)
    if (insertWelSQL) {
      await prisma.$executeRawUnsafe(insertWelSQL);
    } else {
      console.log('[backfill] Skipping WEL insertion (missing workoutExerciseId or date columns)');
    }
    if (updateSetsSQL) {
      await prisma.$executeRawUnsafe(updateSetsSQL);
    } else {
      console.log('[backfill] Skipping direct sets mapping (missing workoutExerciseId or date columns)');
    }

    // Fallback heuristic mapping (per legacy script): for any remaining sets that still have exerciseLogId but no WEL, assign to closest-time WEL per day
    const remainingSetsRes = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) AS c FROM "sets_logs" WHERE "exerciseLogId" IS NOT NULL AND "workoutExerciseLogId" IS NULL;`
    );
    const remainingSets = Number(remainingSetsRes?.[0]?.c ?? 0);
    if (remainingSets > 0) {
      console.log(`[backfill] Running heuristic fallback for ${remainingSets} sets...`);

      // Get distinct day logs (logId) that still have unmapped sets
      const dayRows = await prisma.$queryRawUnsafe<any[]>(
        `SELECT DISTINCT el.${logIdCol} AS log_id
         FROM "exercise_logs" el
         JOIN "sets_logs" s ON s."exerciseLogId" = el.id
         WHERE s."workoutExerciseLogId" IS NULL`
      );

      for (const row of dayRows) {
        const logId = row.log_id;
        const wels = await prisma.$queryRawUnsafe<any[]>(
          `SELECT id, COALESCE("totalTime",0) AS total_time FROM "workout_exercise_logs" WHERE "logId" = $1::uuid`,
          logId
        );
        if (!wels || wels.length === 0) {
          // No WELs for this day; skip like legacy script
          continue;
        }

        // Exercise logs for this day with remaining sets and their sum(times)
        const exLogs = await prisma.$queryRawUnsafe<any[]>(
          `SELECT el.id, COALESCE(SUM(s.times),0) AS sum_times, COUNT(*) AS set_count
           FROM "exercise_logs" el
           JOIN "sets_logs" s ON s."exerciseLogId" = el.id
           WHERE el.${logIdCol} = $1::uuid AND s."workoutExerciseLogId" IS NULL
           GROUP BY el.id`,
          logId
        );

        const assignedWelIds = new Set<string>();

        for (const el of exLogs) {
          const sumTimes = Number(el.sum_times || 0);
          let chosenWelId: string | null = null;

          if (wels.length === 1) {
            chosenWelId = wels[0].id as string;
          } else {
            let best: { id: string; diff: number; unassigned: boolean } | null = null;
            for (const w of wels) {
              const diff = Math.abs(Number(w.total_time || 0) - sumTimes);
              const unassigned = !assignedWelIds.has(w.id);
              const cand = { id: w.id as string, diff, unassigned };
              if (!best || (cand.unassigned && !best.unassigned) || (cand.unassigned === best.unassigned && cand.diff < best.diff)) {
                best = cand;
              }
            }
            chosenWelId = best ? best.id : (wels[0].id as string);
          }

          if (chosenWelId) {
            assignedWelIds.add(chosenWelId);
            await prisma.$executeRawUnsafe(
              `UPDATE "sets_logs" SET "workoutExerciseLogId" = $1::uuid WHERE "exerciseLogId" = $2::uuid AND "workoutExerciseLogId" IS NULL`,
              chosenWelId,
              el.id
            );
          }
        }
      }
    }

    // Recompute totals after mapping
    await prisma.$executeRawUnsafe(recomputeWelTimeSQL);
    await prisma.$executeRawUnsafe(recomputeLogTimeSQL);

    const afterCounts = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
         (SELECT COUNT(*) FROM "exercise_logs") AS exercise_logs,
         (SELECT COUNT(*) FROM "workout_exercise_logs") AS workout_exercise_logs,
         (SELECT COUNT(*) FROM "sets_logs" WHERE "exerciseLogId" IS NOT NULL) AS sets_with_exerciseLogId,
         (SELECT COUNT(*) FROM "sets_logs" WHERE "workoutExerciseLogId" IS NOT NULL) AS sets_with_wel
       ;`
    );
    console.log('[backfill] After:', afterCounts?.[0]);

    await prisma.$executeRawUnsafe('COMMIT');
    console.log('[backfill] Done. You can now run the destructive migration.');
  } catch (err) {
    console.error('[backfill] ERROR:', err);
    try { await prisma.$executeRawUnsafe('ROLLBACK'); } catch {}
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
})();

