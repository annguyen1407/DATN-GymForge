import 'dart:convert';
import 'package:http/http.dart' as http;

class DailyExerciseLogSummary {
  final DateTime date;

  /// sessions: số lần xuất hiện (kể cả trùng) của workoutDayId trong danh sách logs
  final int sessions;

  /// uniqueSessions: số workoutDayId duy nhất (nếu cần dùng sau này)
  final int uniqueSessions;
  final int totalExercises; // count of workoutExerciseLogs
  final int caloriesBurned;
  final int? caloriesIntake;

  const DailyExerciseLogSummary({
    required this.date,
    required this.sessions,
    required this.uniqueSessions,
    required this.totalExercises,
    required this.caloriesBurned,
    required this.caloriesIntake,
  });
}

class ExerciseLogRepository {
  final String baseUrl;
  final http.Client _client;

  ExerciseLogRepository({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

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
    );
  }

  String _fmt(DateTime d) => '${d.toIso8601String().substring(0, 10)}';
}
