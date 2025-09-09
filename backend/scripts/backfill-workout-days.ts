import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function backfillWorkoutDays() {
  console.log('Starting backfill of WorkoutDay and workoutDayId...');

  const plans = await prisma.workoutPlan.findMany({
    select: { id: true },
  });

  for (const plan of plans) {
    const exercises = await prisma.workoutExercise.findMany({
      where: { workoutPlanId: plan.id },
      select: { id: true, dayNumber: true },
    });

    if (exercises.length === 0) continue;

    // Distinct day numbers including null
    const dayNumbersSet = new Set<number | null>();
    for (const ex of exercises) {
      dayNumbersSet.add(ex.dayNumber ?? null);
    }

    const dayNumbers = Array.from(dayNumbersSet);

    // Create day rows for this plan
    const dayIdByNumber = new Map<number | null, string>();
    for (const dn of dayNumbers) {
      const day = await prisma.workoutDay.create({
        data: {
          workoutPlanId: plan.id,
          dayNumber: dn === null ? undefined : dn,
        },
      });
      dayIdByNumber.set(dn, day.id);
    }

    // Update workoutExercise rows to point to the created day
    for (const [dn, dayId] of dayIdByNumber.entries()) {
      await prisma.workoutExercise.updateMany({
        where: { workoutPlanId: plan.id, dayNumber: dn === null ? null : dn },
        data: { workoutDayId: dayId },
      });
    }

    console.log(`Plan ${plan.id}: created ${dayNumbers.length} day(s) and linked exercises.`);
  }

  console.log('Backfill completed.');
}

backfillWorkoutDays()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

