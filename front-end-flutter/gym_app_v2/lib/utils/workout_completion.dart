import '../widgets/exercise_card.dart';

class WorkoutCompletionResult {
  final double
  volumePercent; // % dựa trên load (0..100 hoặc >100 nếu allowOver)
  final double setsPercent; // % số set hoàn thành
  final double hybridPercent; // alpha * volume + (1-alpha) * sets
  final double achievedLoad; // Tổng L_i
  final double targetLoad; // T
  final int totalSetsPlanned;
  final int totalSetsDone;

  const WorkoutCompletionResult({
    required this.volumePercent,
    required this.setsPercent,
    required this.hybridPercent,
    required this.achievedLoad,
    required this.targetLoad,
    required this.totalSetsPlanned,
    required this.totalSetsDone,
  });
}

class WorkoutCompletionCalculatorParams {
  final double repValue; // Giá trị thay thế khi targetWeight=0
  final bool allowOver100; // Cho phép >100%
  final double maxIntensityMultiplier; // Clamp intensity khi > target
  final double hybridAlpha; // Trọng số cho volume trong hybrid

  const WorkoutCompletionCalculatorParams({
    this.repValue = 1.0,
    this.allowOver100 = false,
    this.maxIntensityMultiplier = 1.2,
    this.hybridAlpha = 0.8,
  });
}

/// workoutData structure: exerciseIndex -> List< { set, reps, time, weight, timestamp } >
WorkoutCompletionResult computeWorkoutCompletion({
  required List<ExerciseItem> plannedExercises,
  required Map<int, List<Map<String, dynamic>>> workoutData,
  WorkoutCompletionCalculatorParams params =
      const WorkoutCompletionCalculatorParams(),
}) {
  double totalTargetLoad = 0.0;
  double totalAchievedLoad = 0.0;
  int totalSetsPlanned = 0;
  int totalSetsDone = 0;

  for (int i = 0; i < plannedExercises.length; i++) {
    final ex = plannedExercises[i];
    final targetWeight = ex.weight.toDouble();
    final targetReps = ex.repsCount;
    final setsPlanned = ex.sets;

    totalSetsPlanned += setsPlanned;

    // Target load for this exercise (assuming uniform sets)
    final perSetTarget =
        targetReps * (targetWeight > 0 ? targetWeight : params.repValue);
    final exerciseTargetLoad = perSetTarget * setsPlanned;
    totalTargetLoad += exerciseTargetLoad;

    final loggedSets = workoutData[i] ?? const [];
    totalSetsDone += loggedSets.length;

    for (final set in loggedSets) {
      final doneReps = (set['reps'] ?? 0) as int;
      final usedWeightRaw = set['weight'];
      final usedWeight = usedWeightRaw is int
          ? usedWeightRaw.toDouble()
          : (usedWeightRaw is double ? usedWeightRaw : 0.0);

      // Intensity factor I_i
      double intensity = 1.0;
      if (targetWeight > 0) {
        if (targetWeight > 0) {
          intensity = usedWeight / targetWeight;
          if (intensity > params.maxIntensityMultiplier) {
            intensity = params.maxIntensityMultiplier;
          }
          if (intensity < 0) intensity = 0; // safety
        }
      } else {
        intensity = 1.0; // Bodyweight / no target weight
      }

      final load =
          doneReps *
          (usedWeight > 0 ? usedWeight : params.repValue) *
          intensity;
      totalAchievedLoad += load;
    }
  }

  if (totalTargetLoad <= 0) {
    return const WorkoutCompletionResult(
      volumePercent: 0,
      setsPercent: 0,
      hybridPercent: 0,
      achievedLoad: 0,
      targetLoad: 0,
      totalSetsPlanned: 0,
      totalSetsDone: 0,
    );
  }

  double volumePercent = (totalAchievedLoad / totalTargetLoad) * 100.0;
  if (!params.allowOver100 && volumePercent > 100) volumePercent = 100;
  final setsPercent = totalSetsPlanned > 0
      ? (totalSetsDone / totalSetsPlanned) * 100.0
      : 0.0;
  final hybridPercent =
      params.hybridAlpha * volumePercent +
      (1 - params.hybridAlpha) * setsPercent;

  return WorkoutCompletionResult(
    volumePercent: volumePercent,
    setsPercent: setsPercent,
    hybridPercent: hybridPercent,
    achievedLoad: totalAchievedLoad,
    targetLoad: totalTargetLoad,
    totalSetsPlanned: totalSetsPlanned,
    totalSetsDone: totalSetsDone,
  );
}
