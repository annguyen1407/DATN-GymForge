import '../core/api/api_client.dart';
import '../core/logging/app_logger.dart';

class DailyExerciseLogSummary {
  final DateTime date;

  /// sessions: số lần xuất hiện (kể cả trùng) của workoutDayId trong danh sách logs
  final int sessions;

  /// uniqueSessions: số workoutDayId duy nhất (nếu cần dùng sau này)
  final int uniqueSessions;
  final int totalExercises; // count of workoutExerciseLogs
  final int caloriesBurned;
  final int? caloriesIntake;
  final double? weight; // body weight (kg) if logged that day
  final double? height; // body height (cm) if logged that day
  final String? notes; // general note for that day (root 'notes')
  final List<Map<String, dynamic>>
  workoutExerciseLogsRaw; // raw logs for plan tab grouping
  /// Tổng thời gian tập (phút) trong ngày – optional (backend có thể trả về totalWorkoutTime hoặc totalWorkoutTimeMinutes)
  final int? totalWorkoutTimeMinutes;

  const DailyExerciseLogSummary({
    required this.date,
    required this.sessions,
    required this.uniqueSessions,
    required this.totalExercises,
    required this.caloriesBurned,
    required this.caloriesIntake,
    required this.weight,
    required this.height,
    required this.notes,
    required this.workoutExerciseLogsRaw,
    required this.totalWorkoutTimeMinutes,
  });
}

class ExerciseLogRepository {
  final String baseUrl;
  ExerciseLogRepository({required this.baseUrl});

  // --- Weekly Stats Models ---
  // Represents one day's aggregated stats inside a weekly response.
  // Fields kept minimal for current UI (totalSets, totalCaloriesBurned, totalWorkoutTime)
  // but we store extra numbers for future charts (exercises, reps, avgWeight).
  WeeklyDailyStat _parseWeeklyDaily(Map<String, dynamic> m) {
    DateTime? date;
    try {
      if (m['date'] is String) {
        date = DateTime.tryParse(m['date'] as String);
      }
    } catch (_) {}
    return WeeklyDailyStat(
      date: date,
      totalExercises: _asInt(m['totalExercises']),
      totalSets: _asInt(m['totalSets']),
      totalReps: _asInt(m['totalReps']),
      totalCaloriesBurned: _asInt(m['totalCaloriesBurned']),
      totalWorkoutTime: _asInt(m['totalWorkoutTime']),
      averageWeight: (m['averageWeight'] is num)
          ? (m['averageWeight'] as num).toDouble()
          : 0,
      workoutPlansCompleted: (m['workoutPlansCompleted'] is List)
          ? (m['workoutPlansCompleted'] as List).whereType<String>().toList(
              growable: false,
            )
          : const <String>[],
    );
  }

  int _asInt(dynamic v) => (v is num) ? v.toInt() : 0;

  Future<WeeklyExerciseStats?> fetchWeeklyStats({
    required String userId,
    required DateTime weekStart, // Monday start (backend expects YYYY-MM-DD)
  }) async {
    final startStr = _fmt(weekStart);
    final path = '/exercise-logs/stats/weekly/$userId/$startStr';
    try {
      final apiRes = await ApiClient.instance.requestJson('GET', path);
      if (apiRes.status != 200 || apiRes.data is! Map<String, dynamic>) {
        AppLogger.warn(
          'Weekly stats failed status ${apiRes.status}',
          tag: 'ExerciseLogRepo',
        );
        return null;
      }
      final decoded = apiRes.data as Map<String, dynamic>;
      final dailyRaw = decoded['dailyStats'];
      final daily = (dailyRaw is List)
          ? dailyRaw
                .whereType<Map<String, dynamic>>()
                .map(_parseWeeklyDaily)
                .toList(growable: false)
          : const <WeeklyDailyStat>[];
      return WeeklyExerciseStats(
        weekStart: DateTime.tryParse(decoded['weekStart'] ?? '') ?? weekStart,
        weekEnd: DateTime.tryParse(decoded['weekEnd'] ?? ''),
        totalWorkoutDays: _asInt(decoded['totalWorkoutDays']),
        totalExercises: _asInt(decoded['totalExercises']),
        totalCaloriesBurned: _asInt(decoded['totalCaloriesBurned']),
        averageDailyWorkoutTime: _asInt(decoded['averageDailyWorkoutTime']),
        dailyStats: daily,
      );
    } catch (e, st) {
      AppLogger.error(
        'Weekly stats error: $e',
        tag: 'ExerciseLogRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<DailyExerciseLogSummary?> fetchDailySummary({
    required String userId,
    required DateTime date,
  }) async {
    final dateStr = _fmt(date);
    final path =
        '/exercise-logs/user/$userId?startDate=$dateStr&endDate=$dateStr';
    try {
      final apiRes = await ApiClient.instance.requestJson('GET', path);
      if (apiRes.status != 200 ||
          apiRes.data is! List ||
          (apiRes.data as List).isEmpty) {
        AppLogger.warn(
          'Daily summary failed status ${apiRes.status}',
          tag: 'ExerciseLogRepo',
        );
        return null;
      }
      final decoded = apiRes.data as List;
      final first = decoded.first as Map<String, dynamic>;

      final workoutExerciseLogs = (first['workoutExerciseLogs'] as List?) ?? [];

      final distinctDayIds = <String>{};
      int workoutDayIdOccurrences = 0; // đếm cả trùng
      // Root caloriesBurned (nếu backend đã tổng hợp). Nếu null -> sẽ cộng từ từng exercise.
      int? aggregateCalories = first['caloriesBurned'] is num
          ? (first['caloriesBurned'] as num).round()
          : null;
      final caloriesIntake = first['caloriesIntake'] is num
          ? (first['caloriesIntake'] as num).round()
          : null;

      int perExerciseCalories = 0;

      for (final item in workoutExerciseLogs) {
        if (item is Map<String, dynamic>) {
          final workoutExercise =
              item['workoutExercise'] as Map<String, dynamic>?;
          final wid = workoutExercise?['workoutDayId'];
          if (wid is String) {
            distinctDayIds.add(wid);
            workoutDayIdOccurrences++; // mỗi lần gặp tăng
          }
          // Tích luỹ per-exercise nếu có để fallback (hoặc đối chiếu)
          if (item['caloriesBurned'] is num) {
            perExerciseCalories += (item['caloriesBurned'] as num).round();
          }
        }
      }

      // Nếu không có workoutDayId nào hợp lệ nhưng có logs, occurrences = 0; fallback: dùng length
      if (workoutDayIdOccurrences == 0) {
        workoutDayIdOccurrences = workoutExerciseLogs.length;
      }
      // Quyết định caloriesBurned: ưu tiên aggregate nếu có, nếu không có dùng per-exercise sum.
      final caloriesBurned = aggregateCalories ?? perExerciseCalories;

      // total workout time: backend có thể cung cấp dưới các key khác nhau (seconds hoặc minutes)
      int? totalWorkoutTimeMinutes;
      if (first['totalWorkoutTimeMinutes'] is num) {
        totalWorkoutTimeMinutes = (first['totalWorkoutTimeMinutes'] as num).round();
      } else if (first['totalWorkoutTime'] is num) {
        // giả định backend đang trả về phút (đồng nhất với điều chỉnh định dạng trước đó)
        totalWorkoutTimeMinutes = (first['totalWorkoutTime'] as num).round();
      }

      return DailyExerciseLogSummary(
        date: date,
        sessions: workoutDayIdOccurrences,
        uniqueSessions: distinctDayIds.length,
        totalExercises: workoutExerciseLogs.length,
        caloriesBurned: caloriesBurned,
        caloriesIntake: caloriesIntake,
        weight: first['weight'] is num
            ? (first['weight'] as num).toDouble()
            : null,
        height: first['height'] is num
            ? (first['height'] as num).toDouble()
            : null,
        notes: first['notes'] is String ? (first['notes'] as String) : null,
        workoutExerciseLogsRaw: workoutExerciseLogs
            .whereType<Map<String, dynamic>>()
            .toList(growable: false),
    totalWorkoutTimeMinutes: totalWorkoutTimeMinutes,
      );
    } catch (e, st) {
      AppLogger.error(
        'Daily summary error: $e',
        tag: 'ExerciseLogRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);
}

class WeeklyExerciseStats {
  final DateTime weekStart;
  final DateTime? weekEnd;
  final int totalWorkoutDays;
  final int totalExercises;
  final int totalCaloriesBurned;
  final int averageDailyWorkoutTime; // seconds (backend value)
  final List<WeeklyDailyStat> dailyStats;
  const WeeklyExerciseStats({
    required this.weekStart,
    required this.weekEnd,
    required this.totalWorkoutDays,
    required this.totalExercises,
    required this.totalCaloriesBurned,
    required this.averageDailyWorkoutTime,
    required this.dailyStats,
  });
}

class WeeklyDailyStat {
  final DateTime? date;
  final int totalExercises;
  final int totalSets;
  final int totalReps;
  final int totalCaloriesBurned;
  final int totalWorkoutTime; // seconds
  final double averageWeight;
  final List<String> workoutPlansCompleted;
  const WeeklyDailyStat({
    required this.date,
    required this.totalExercises,
    required this.totalSets,
    required this.totalReps,
    required this.totalCaloriesBurned,
    required this.totalWorkoutTime,
    required this.averageWeight,
    required this.workoutPlansCompleted,
  });
}

/// Parsed exercise log item (minimal fields for plan tab)
class WorkoutExerciseLogParsed {
  final String? id;
  final String? exerciseName;
  final double? progressPercent; // 0..100
  final int? targetSets;
  final int? targetReps;
  final double? targetWeight;
  final Map<String, dynamic> raw;
  const WorkoutExerciseLogParsed({
    required this.id,
    required this.exerciseName,
    required this.progressPercent,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.raw,
  });

  factory WorkoutExerciseLogParsed.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseLogParsed(
      id: json['id']?.toString(),
      exerciseName: json['exerciseName']?.toString(),
      progressPercent: () {
        final v = json['progressPercent'];
        if (v is num) return v.toDouble();
        return null;
      }(),
      targetSets: json['targetSets'] is num
          ? (json['targetSets'] as num).toInt()
          : null,
      targetReps: json['targetReps'] is num
          ? (json['targetReps'] as num).toInt()
          : null,
      targetWeight: json['targetWeight'] is num
          ? (json['targetWeight'] as num).toDouble()
          : null,
      raw: json,
    );
  }
}

/// Grouped by workoutDayId for plan tab display
class WorkoutPlanDayGroup {
  final String workoutDayId;
  final int? dayNumber;
  final String? planName;
  final String? planType;
  final List<WorkoutExerciseLogParsed> exercises;
  const WorkoutPlanDayGroup({
    required this.workoutDayId,
    required this.dayNumber,
    required this.planName,
    required this.planType,
    required this.exercises,
  });

  double get averageProgress {
    if (exercises.isEmpty) return 0;
    final total = exercises.fold<double>(
      0,
      (p, e) => p + (e.progressPercent ?? 0),
    );
    return total / exercises.length; // still 0..100
  }
}

/// Utility to group raw workoutExerciseLogs into plan/day groups.
List<WorkoutPlanDayGroup> parseWorkoutLogsFromJson(
  List<Map<String, dynamic>> raw,
) {
  final Map<String, List<WorkoutExerciseLogParsed>> bucket = {};
  final Map<String, (int? dayNumber, String? planName, String? planType)> meta =
      {};
  for (final item in raw) {
    final workoutExercise = item['workoutExercise'] as Map<String, dynamic>?;
    final String dayId =
        workoutExercise?['workoutDayId']?.toString() ?? 'unknown';
    final int? dayNumber = (item['dayNumber'] is num)
        ? (item['dayNumber'] as num).toInt()
        : (workoutExercise?['dayNumber'] is num
              ? (workoutExercise?['dayNumber'] as num).toInt()
              : null);
    final planObj = workoutExercise?['workoutPlan'] as Map<String, dynamic>?;
    final planName =
        planObj?['name']?.toString() ??
        workoutExercise?['planName']?.toString();
    final planType =
        planObj?['planType']?.toString() ?? planObj?['type']?.toString();
    bucket.putIfAbsent(dayId, () => []);
    bucket[dayId]!.add(WorkoutExerciseLogParsed.fromJson(item));
    meta.putIfAbsent(dayId, () => (dayNumber, planName, planType));
  }
  return bucket.entries
      .map((e) {
        final m = meta[e.key];
        return WorkoutPlanDayGroup(
          workoutDayId: e.key,
          dayNumber: m?.$1,
          planName: m?.$2,
          planType: m?.$3,
          exercises: e.value,
        );
      })
      .toList(growable: false);
}
