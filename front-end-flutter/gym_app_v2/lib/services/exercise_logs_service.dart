import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../widgets/exercise_card.dart';
import '../core/auth/token_manager.dart';

class ExerciseStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkoutDate;

  ExerciseStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastWorkoutDate,
  });

  factory ExerciseStreak.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return ExerciseStreak(
      currentStreak: (json['currentStreak'] ?? 0) as int,
      longestStreak: (json['longestStreak'] ?? 0) as int,
      lastWorkoutDate: parseDate(json['lastWorkoutDate']),
    );
  }
}

class ExerciseSetLogPayload {
  final int setNumber;
  final int reps;
  final int times; // seconds or duration
  final int weight; // integer kg as per requirement
  final double caloriesBurned; // placeholder 0

  ExerciseSetLogPayload({
    required this.setNumber,
    required this.reps,
    required this.times,
    required this.weight,
    this.caloriesBurned = 0,
  });

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'reps': reps,
    'times': times,
    'weight': weight,
    'caloriesBurned': caloriesBurned,
  };
}

class ExerciseLogPayload {
  final String? userId; // may be null if backend derives from token
  final String workoutPlanId;
  final String workoutExerciseId; // id of workout day exercise
  final String
  workoutDayId; // id của workout day (để backend thống kê theo ngày)
  final int dayNumber;
  final DateTime date;
  final DateTime workoutDayDate; // ngày thực tế của workout day
  final String exerciseName;
  final double totalCaloriesBurned; // placeholder 0
  final double progressPercent; // hybrid percent
  final List<ExerciseSetLogPayload> sets;
  // Target meta (mirror từ cấu hình ngày tập)
  final int? targetSets;
  final int? targetReps;
  final double? targetWeight;
  final int? restTimeSec;

  ExerciseLogPayload({
    required this.userId,
    required this.workoutPlanId,
    required this.workoutExerciseId,
    required this.workoutDayId,
    required this.dayNumber,
    required this.date,
    required this.workoutDayDate,
    required this.exerciseName,
    required this.totalCaloriesBurned,
    required this.progressPercent,
    required this.sets,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.restTimeSec,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'workoutPlanId': workoutPlanId,
    'workoutExerciseId': workoutExerciseId,
    'workoutDayId': workoutDayId,
    'dayNumber': dayNumber,
    'date': date.toIso8601String().split('T').first,
    'workoutDayDate': workoutDayDate.toIso8601String().split('T').first,
    'exerciseName': exerciseName,
    'totalCaloriesBurned': totalCaloriesBurned,
    'progressPercent': progressPercent,
    'sets': sets.map((e) => e.toJson()).toList(),
    'targetSets': targetSets,
    'targetReps': targetReps,
    'targetWeight': targetWeight,
    'restTimeSec': restTimeSec,
  };

  /// Chỉ gửi các field backend hiện yêu cầu tối thiểu (giảm rủi ro mismatch schema)
  Map<String, dynamic> toBackendMinimalJson() => {
    if (userId != null) 'userId': userId,
    'workoutPlanId': workoutPlanId,
    'workoutExerciseId': workoutExerciseId,
    'dayNumber': dayNumber,
    'date': date.toIso8601String().split('T').first,
    'exerciseName': exerciseName,
    'totalCaloriesBurned': totalCaloriesBurned,
    'progressPercent': progressPercent,
    'sets': sets.map((e) => e.toJson()).toList(),
  };
}

class ExerciseLogsService {
  ExerciseLogsService._();
  static final ExerciseLogsService instance = ExerciseLogsService._();

  Future<ApiResponse<ExerciseStreak>> getMyStreaks() async {
    // Correct endpoint per backend controller (@Get('streaks/my')).
    // Add fallback to legacy path without /my if first call 404 (for backward compatibility).
    final primaryPath = '/exercise-logs/streaks/my';
    final legacyPath = '/exercise-logs/streaks';
    ApiResponse<dynamic> res = await ApiClient.instance.requestJson(
      'GET',
      primaryPath,
    );
    if (res.status == 404) {
      // Fallback attempt
      final fallback = await ApiClient.instance.requestJson('GET', legacyPath);
      // Only replace if fallback succeeded (2xx)
      if (fallback.status >= 200 && fallback.status < 300) {
        res = fallback;
      }
    }
    if (res.data is Map) {
      try {
        final streak = ExerciseStreak.fromJson(
          res.data as Map<String, dynamic>,
        );
        return ApiResponse<ExerciseStreak>(
          status: res.status,
          data: streak,
          raw: res.raw,
        );
      } catch (e) {
        return ApiResponse<ExerciseStreak>(
          status: res.status,
          error: ApiErrorType.decode,
          message: 'Decode streak failed: $e',
          raw: res.raw,
        );
      }
    }
    return ApiResponse<ExerciseStreak>(
      status: res.status,
      error: res.error ?? ApiErrorType.unknown,
      message: res.message ?? 'Unexpected streak response',
      raw: res.raw,
    );
  }

  Future<ApiResponse<dynamic>> createLog(ExerciseLogPayload payload) async {
    final res = await ApiClient.instance.requestJson(
      'POST',
      '/exercise-logs',
      // Dùng minimal payload để chắc chắn tương thích backend hiện tại
      body: payload.toBackendMinimalJson(),
    );
    return res;
  }

  /// Compute per-exercise hybrid % using same logic but isolating 1 exercise.
  double computeExerciseHybridPercent({
    required ExerciseItem exercise,
    required List<Map<String, dynamic>> loggedSets,
    double repValue = 1,
    double maxIntensityMultiplier = 1.2,
    double hybridAlpha = 0.8,
    bool allowOver100 = false,
  }) {
    if (exercise.sets <= 0 || exercise.repsCount <= 0) return 0;
    final targetWeight = exercise.weight.toDouble();
    final perSetTarget =
        exercise.repsCount * (targetWeight > 0 ? targetWeight : repValue);
    final targetLoad = perSetTarget * exercise.sets;

    double achievedLoad = 0;
    for (final s in loggedSets) {
      final reps = (s['reps'] ?? 0) as int;
      final wRaw = s['weight'];
      final w = wRaw is int ? wRaw.toDouble() : (wRaw is double ? wRaw : 0.0);
      double intensity = 1.0;
      if (targetWeight > 0) {
        intensity = targetWeight == 0 ? 1 : (w / targetWeight);
        if (intensity > maxIntensityMultiplier) {
          intensity = maxIntensityMultiplier;
        }
        if (intensity < 0) {
          intensity = 0;
        }
      }
      final load = reps * (w > 0 ? w : repValue) * intensity;
      achievedLoad += load;
    }

    if (targetLoad <= 0) {
      return 0;
    }
    double volumePercent = achievedLoad / targetLoad * 100;
    if (!allowOver100 && volumePercent > 100) {
      volumePercent = 100;
    }
    final setsPercent = loggedSets.isEmpty
        ? 0
        : (loggedSets.length / exercise.sets * 100).clamp(0, 100);
    final hybrid =
        hybridAlpha * volumePercent + (1 - hybridAlpha) * setsPercent;
    return hybrid;
  }

  /// Build payloads for each exercise (including those not completed -> progress 0).
  Future<List<ExerciseLogPayload>> buildPayloads({
    required List<ExerciseItem> exercises,
    required Map<int, List<Map<String, dynamic>>> workoutData,
    required String workoutPlanId,
    required int dayNumber,
    required DateTime workoutDayDate,
    required String workoutDayId,
    String? userId,
    double repValue = 1,
  }) async {
    final List<ExerciseLogPayload> list = [];
    for (int i = 0; i < exercises.length; i++) {
      final ex = exercises[i];
      final loggedSets = workoutData[i] ?? [];
      final hybridPercent = computeExerciseHybridPercent(
        exercise: ex,
        loggedSets: loggedSets,
        repValue: repValue,
      );
      final setsPayload = loggedSets
          // Optional guard: bỏ qua set có time=0 và reps=0 để tránh noise dữ liệu
          // TODO: Cân nhắc gửi nhưng đánh dấu flag isEmptySet thay vì bỏ qua hoàn toàn nếu cần phân tích sau
          .where((s) {
            final reps = s['reps'] as int? ?? 0;
            final timeSec = s['time'] as int? ?? 0;
            // Giữ lại nếu có reps > 0 hoặc thời gian > 0
            return reps > 0 || timeSec > 0;
          })
          .map(
            (s) => ExerciseSetLogPayload(
              setNumber: s['set'] as int? ?? 0,
              reps: s['reps'] as int? ?? 0,
              times: s['time'] as int? ?? 0,
              weight: () {
                final w = s['weight'];
                if (w is int) return w;
                if (w is double) return w.floor();
                return 0;
              }(),
            ),
          )
          .toList();
      list.add(
        ExerciseLogPayload(
          userId: userId,
          workoutPlanId: workoutPlanId,
          workoutExerciseId: ex.id ?? '',
          workoutDayId: workoutDayId,
          dayNumber: dayNumber,
          date: DateTime.now(),
          workoutDayDate: workoutDayDate,
          exerciseName: ex.name,
          totalCaloriesBurned: 0,
          progressPercent: double.parse(hybridPercent.toStringAsFixed(1)),
          sets: setsPayload,
          targetSets: ex.sets,
          targetReps: ex.repsCount,
          targetWeight: ex.weight.toDouble(),
          restTimeSec: ex.restTime,
        ),
      );
    }
    return list;
  }

  /// Helper to fetch user id via token manager (if backend still requires sending userId field)
  Future<String?> getCurrentUserId() =>
      TokenManager.instance.getCurrentUserId();
}
