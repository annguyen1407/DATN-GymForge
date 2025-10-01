import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // No-op on current schema: ExerciseLog model has been removed.
  // Keeping this script to avoid build failures and to document that backfill already occurred.
  const setsCount = await prisma.setsLog.count();
  console.log('Backfill no-op: ExerciseLog removed. setsLog rows count =', setsCount);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


  // let totalSets = 0;
  // let assignedSets = 0;
  // let skippedSets = 0;

//   // Load all ExerciseLogs with their sets
//   const exerciseLogs = await prisma.exerciseLog.findMany({ include: { setsLog: true } });

//   // Group ExerciseLogs by workoutLogId (day Log)
//   const byDay: Record<string, { id: string; setsLog: { id: string; times: number | null }[] }[]> = {};
//   for (const el of exerciseLogs) {
//     const arr = byDay[el.workoutLogId] || (byDay[el.workoutLogId] = []);
//     arr.push({ id: el.id, setsLog: el.setsLog.map(s => ({ id: s.id, times: s.times })) });
//     totalSets += el.setsLog.length;
//   }

//   for (const [workoutLogId, exLogs] of Object.entries(byDay)) {
//     const wels = await prisma.workoutExerciseLog.findMany({ where: { logId: workoutLogId } });
//     if (wels.length === 0) {
//       // No WELs for this day; skip these sets
//       const daySets = exLogs.reduce((acc, e) => acc + e.setsLog.length, 0);
//       skippedSets += daySets;
//       continue;
//     }

//     // Track which WELs have been assigned to avoid over-allocating duplicates when multiple exercise logs exist
//     const assignedWelIds = new Set<string>();

//     for (const el of exLogs) {
//       const sumTimes = el.setsLog.reduce((acc, s) => acc + (s.times || 0), 0);

//       let chosenWelId: string | null = null;
//       if (wels.length === 1) {
//         chosenWelId = wels[0].id;
//       } else {
//         // Pick WEL with closest totalTime, prefer unassigned
//         let best: { id: string; diff: number; isUnassigned: boolean } | null = null;
//         for (const w of wels) {
//           const diff = Math.abs((w.totalTime || 0) - sumTimes);
//           const isUnassigned = !assignedWelIds.has(w.id);
//           const candidate = { id: w.id, diff, isUnassigned };
//           if (
//             !best ||
//             candidate.isUnassigned && !best.isUnassigned ||
//             (candidate.isUnassigned === best.isUnassigned && candidate.diff < best.diff)
//           ) {
//             best = candidate;
//           }
//         }
//         chosenWelId = best ? best.id : wels[0].id;
//       }

//       if (chosenWelId) {
//         assignedWelIds.add(chosenWelId);
//         if (el.setsLog.length > 0) {
//           await prisma.setsLog.updateMany({
//             where: { exerciseLogId: el.id },
//             data: { workoutExerciseLogId: chosenWelId },
//           });
//           assignedSets += el.setsLog.length;
//         }
//       } else {
//         skippedSets += el.setsLog.length;
//       }
//     }
//   }

//   const remaining = await prisma.setsLog.count({ where: { workoutExerciseLogId: null } });

//   console.log('Backfill SetsLog → WorkoutExerciseLog completed');
//   console.log({ totalSets, assignedSets, skippedSets, remainingUnassigned: remaining });

