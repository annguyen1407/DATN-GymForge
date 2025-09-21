import 'dart:convert';
import 'package:http/http.dart' as http;
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

  const DailyExerciseLogSummary({
    required this.date,
    required this.sessions,
    required this.uniqueSessions,
    required this.totalExercises,
    required this.caloriesBurned,
    required this.caloriesIntake,
    required this.weight,
    required this.height,
  });
}

class ExerciseLogRepository {
  final String baseUrl;
  final http.Client _client;

  ExerciseLogRepository({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

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
    required String token,
  }) async {
    final startStr = _fmt(weekStart);
    final uri = Uri.parse(
      '$baseUrl/exercise-logs/stats/weekly/$userId/$startStr',
    );
    try {
      final resp = await _client.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode != 200) {
        AppLogger.warn(
          'Weekly stats failed status ${resp.statusCode}',
          tag: 'ExerciseLogRepo',
        );
        return null; // graceful fallback – UI shows empty chart
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) return null;
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
    required String token,
  }) async {
    final dateStr = _fmt(date);
    final uri = Uri.parse(
      '$baseUrl/exercise-logs/user/$userId?startDate=$dateStr&endDate=$dateStr',
    );

    final resp = await _client.get(
      uri,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      // Throw để UI hiển thị lỗi thay vì âm thầm trả về null -> TodayStat = 0
      throw Exception('Fetch daily summary failed (status ${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    if (decoded is! List || decoded.isEmpty) return null;
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

    return DailyExerciseLogSummary(
      date: date,
      sessions: workoutDayIdOccurrences,
      uniqueSessions: distinctDayIds.length,
      totalExercises: workoutExerciseLogs.length,
      caloriesBurned: caloriesBurned,
      caloriesIntake: caloriesIntake,
      weight: first['weight'] is num ? (first['weight'] as num).toDouble() : null,
      height: first['height'] is num ? (first['height'] as num).toDouble() : null,
    );
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
