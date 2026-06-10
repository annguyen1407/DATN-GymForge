const API_URL = "http://localhost:3000/exercises";

const TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmZjIzM2QxYS01MDkxLTQxZmEtOGNlYy1lZGM4ODkwY2FmNjIiLCJlbWFpbCI6ImFubmd1eWVuMTQwNzAxQGdtYWlsLmNvbSIsInJvbGUiOiJBRE1JTiIsImlhdCI6MTc4MTA4Njg3MywiZXhwIjoxNzgxMDg3NzczfQ.Z2-aCSXYZQeclYjlXHc-msu1gS1GB_3NXL_DfIH8h40";

const USER_ID = "ff233d1a-5091-41fa-8cec-edc8890caf62";

const equipment = {
  bodyweight: "33c18f96-5422-400e-8fb7-fdebf16baf28",
  dumbbell: "e7187419-6ea4-4005-9d29-1f847c3467c4",
  barbell: "367807d8-e2ad-49b9-b45b-dcd7788998ba",
  benchPressMachine: "a9fc001f-3c08-46b0-b4b4-488fac8e9f7c",
  chestFlyMachine: "3d967407-2756-4e4f-8841-f045877c4220",
  latPulldownMachine: "ad75dbcf-bb66-4515-a8d0-d1daa400184f",
  cableMachine: "361563a5-2418-478a-97f4-0159161d53b9",
  squatRack: "c7b9f050-0643-48a2-8fe2-790566a267bf",
  legPressMachine: "9d35e06c-5517-44eb-81c0-936b2a2ae3f1",
  legExtensionMachine: "f6fcd76d-655e-49f1-9824-62c87560e310",
  legCurlMachine: "45d8ff89-9beb-4fc6-919e-939d747a5426",
  shoulderPressMachine: "9bd9abc4-615d-44eb-9eaf-a5f81c569d71",
  seatedRowMachine: "57243172-0616-43d0-8994-73b588b85d7d",
  hackSquatMachine: "e238eef8-ae12-4c7b-950a-c94b08227bab",
  calfRaiseMachine: "adb0ffe1-06ec-4408-b044-4ab356d117e7",
  abCrunchBench: "e18b0cec-1987-48f4-a681-060c58ece180",
  adjustableBench: "26481338-b7f6-4449-9f9f-7926da921982",
  treadmill: "6eeee7c7-2180-4128-bfa7-3b5d7cbbac17",
  exerciseBike: "32f17989-4bec-4ea7-8bc2-cc0a52956cb0",
  elliptical: "bcb76c6c-16e7-4da7-a136-248cc8e3ca3a",
  smithMachine: "a29eb88f-c313-44d6-b422-6ab646816284",
};

const muscle = {
  chest: "fe5efdfe-ca5b-4f45-bdd5-9f941fbcc919",
  back: "061e744f-530a-434e-8a94-87014759b060",
  shoulders: "f0cd5bb5-b68b-4fc3-b5cc-c9bdbc92eefe",
  biceps: "1f6b4cf9-1b5b-41f1-b6f1-55dd14ab9515",
  triceps: "d2f396f0-f1f3-4ec6-9c0a-ff95196de344",
  forearms: "93989fe2-39dd-4a6a-9a0a-bd0edea0462d",
  abs: "48b7128e-912e-4c0a-bf8e-0decae635900",
  obliques: "1b97249e-fb4b-4dcf-b325-6eba7f3c1da2",
  quadriceps: "f9960ae0-1efd-4e6d-95d7-df66e92e027c",
  hamstrings: "fe1c749e-ea0f-4e40-bf66-cf609e2efb42",
  glutes: "b44721c2-5b30-413b-94d5-a777fd7735a7",
  calves: "b0f1f687-c318-4e92-9abb-6712ace34909",
  traps: "c084554a-e883-4d6c-9570-e07e9e0e9aa7",
  lowerBack: "e4cef2d1-4923-4bb7-a451-4b65f937ae65",
  fullBody: "fb11914d-67c5-4966-bf49-f4ade70fca88",
  cardio: "7c712019-0f1a-432b-ac19-eeb2e5cdc2e0",
};

const exercises = [
  ["Push-up", equipment.bodyweight, [muscle.chest, muscle.triceps, muscle.shoulders], 3.8, 0, 3, 15],
  ["Pull-up", equipment.bodyweight, [muscle.back, muscle.biceps], 8.0, 0, 3, 8],
  ["Chin-up", equipment.bodyweight, [muscle.back, muscle.biceps], 8.0, 0, 3, 8],
  ["Bodyweight Squat", equipment.bodyweight, [muscle.quadriceps, muscle.glutes], 5.0, 0, 3, 20],
  ["Plank", equipment.bodyweight, [muscle.abs, muscle.obliques], 3.0, 0, 3, 1],
  ["Crunch", equipment.bodyweight, [muscle.abs], 3.8, 0, 3, 20],
  ["Mountain Climber", equipment.bodyweight, [muscle.abs, muscle.cardio], 8.0, 0, 3, 30],
  ["Burpee", equipment.bodyweight, [muscle.fullBody, muscle.cardio], 8.0, 0, 3, 12],
  ["Lunge", equipment.bodyweight, [muscle.quadriceps, muscle.glutes], 4.0, 0, 3, 12],
  ["Glute Bridge", equipment.bodyweight, [muscle.glutes, muscle.hamstrings], 3.5, 0, 3, 15],

  ["Dumbbell Bench Press", equipment.dumbbell, [muscle.chest, muscle.triceps, muscle.shoulders], 6.0, 10, 3, 10],
  ["Dumbbell Fly", equipment.dumbbell, [muscle.chest], 5.0, 8, 3, 12],
  ["Dumbbell Shoulder Press", equipment.dumbbell, [muscle.shoulders, muscle.triceps], 6.0, 8, 3, 10],
  ["Dumbbell Lateral Raise", equipment.dumbbell, [muscle.shoulders], 4.5, 5, 3, 12],
  ["Dumbbell Front Raise", equipment.dumbbell, [muscle.shoulders], 4.5, 5, 3, 12],
  ["Dumbbell Biceps Curl", equipment.dumbbell, [muscle.biceps, muscle.forearms], 3.5, 8, 3, 12],
  ["Hammer Curl", equipment.dumbbell, [muscle.biceps, muscle.forearms], 3.5, 8, 3, 12],
  ["Dumbbell Triceps Extension", equipment.dumbbell, [muscle.triceps], 3.5, 8, 3, 12],
  ["Dumbbell Row", equipment.dumbbell, [muscle.back, muscle.biceps], 5.5, 10, 3, 10],
  ["Dumbbell Shrug", equipment.dumbbell, [muscle.traps], 4.0, 12, 3, 12],

  ["Barbell Bench Press", equipment.barbell, [muscle.chest, muscle.triceps, muscle.shoulders], 6.0, 40, 4, 8],
  ["Barbell Squat", equipment.squatRack, [muscle.quadriceps, muscle.glutes, muscle.hamstrings], 7.0, 50, 4, 8],
  ["Deadlift", equipment.barbell, [muscle.back, muscle.lowerBack, muscle.glutes, muscle.hamstrings], 7.5, 60, 4, 6],
  ["Barbell Row", equipment.barbell, [muscle.back, muscle.biceps], 6.0, 40, 4, 8],
  ["Overhead Press", equipment.barbell, [muscle.shoulders, muscle.triceps], 6.0, 30, 4, 8],
  ["Romanian Deadlift", equipment.barbell, [muscle.hamstrings, muscle.glutes, muscle.lowerBack], 6.0, 40, 3, 10],
  ["Barbell Curl", equipment.barbell, [muscle.biceps], 3.5, 20, 3, 10],
  ["Close Grip Bench Press", equipment.barbell, [muscle.triceps, muscle.chest], 5.5, 35, 3, 10],
  ["Hip Thrust", equipment.barbell, [muscle.glutes, muscle.hamstrings], 6.0, 50, 3, 10],
  ["Good Morning", equipment.barbell, [muscle.lowerBack, muscle.hamstrings, muscle.glutes], 5.0, 30, 3, 10],

  ["Bench Press Machine", equipment.benchPressMachine, [muscle.chest, muscle.triceps], 5.0, 30, 3, 10],
  ["Chest Fly Machine", equipment.chestFlyMachine, [muscle.chest], 4.5, 25, 3, 12],
  ["Lat Pulldown", equipment.latPulldownMachine, [muscle.back, muscle.biceps], 5.5, 35, 3, 10],
  ["Cable Row", equipment.seatedRowMachine, [muscle.back, muscle.biceps], 5.0, 35, 3, 10],
  ["Cable Triceps Pushdown", equipment.cableMachine, [muscle.triceps], 3.5, 20, 3, 12],
  ["Cable Biceps Curl", equipment.cableMachine, [muscle.biceps], 3.5, 20, 3, 12],
  ["Cable Face Pull", equipment.cableMachine, [muscle.shoulders, muscle.traps], 4.0, 20, 3, 12],
  ["Cable Lateral Raise", equipment.cableMachine, [muscle.shoulders], 4.0, 10, 3, 12],
  ["Cable Wood Chop", equipment.cableMachine, [muscle.obliques, muscle.abs], 4.5, 15, 3, 12],
  ["Cable Crossover", equipment.cableMachine, [muscle.chest], 4.5, 20, 3, 12],

  ["Leg Press", equipment.legPressMachine, [muscle.quadriceps, muscle.glutes], 6.0, 80, 4, 10],
  ["Leg Extension", equipment.legExtensionMachine, [muscle.quadriceps], 4.0, 30, 3, 12],
  ["Leg Curl", equipment.legCurlMachine, [muscle.hamstrings], 4.0, 30, 3, 12],
  ["Hack Squat", equipment.hackSquatMachine, [muscle.quadriceps, muscle.glutes], 6.0, 60, 4, 10],
  ["Standing Calf Raise", equipment.calfRaiseMachine, [muscle.calves], 4.0, 40, 4, 15],
  ["Shoulder Press Machine", equipment.shoulderPressMachine, [muscle.shoulders, muscle.triceps], 5.0, 30, 3, 10],
  ["Ab Crunch Machine", equipment.abCrunchBench, [muscle.abs], 3.5, 20, 3, 15],
  ["Treadmill Running", equipment.treadmill, [muscle.cardio, muscle.fullBody], 9.0, 0, 1, 1],
  ["Exercise Bike", equipment.exerciseBike, [muscle.cardio, muscle.quadriceps], 7.0, 0, 1, 1],
  ["Elliptical Trainer", equipment.elliptical, [muscle.cardio, muscle.fullBody], 6.5, 0, 1, 1],
];

async function createExercise(item) {
  const [name, equipmentId, muscleGroupIds, met, defaultWeight, defaultSets, defaultReps] = item;

  const body = {
    userId: USER_ID,
    name,
    equipmentId,
    description: `${name} is a common exercise used for strength, endurance, or conditioning training.`,
    instruction: `Perform ${name} with controlled movement, proper posture, and full range of motion.`,
    videoUrl: null,
    gifUrl: null,
    met,
    defaultWeight,
    defaultSets,
    defaultReps,
    restTime: 60,
    defaultTimePerSetSec: 45,
    muscleGroupIds,
  };

  const res = await fetch(API_URL, {
    method: "POST",
    headers: {
      accept: "*/*",
      Authorization: `Bearer ${TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errorText = await res.text();
    console.log(`❌ Failed: ${name}`);
    console.log(errorText);
    return;
  }

  const data = await res.json().catch(() => null);
  console.log(`✅ Created: ${name}`, data?.id || "");
}

async function main() {
  for (const exercise of exercises) {
    await createExercise(exercise);
  }

  console.log("Done seeding 50 exercises.");
}

main();