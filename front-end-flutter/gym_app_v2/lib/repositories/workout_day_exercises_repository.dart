import '../core/api/api_client.dart';

class WorkoutDayExerciseDto {
  final String id;
  final String workoutPlanId;
  final String workoutDayId;
  final String exerciseId;
  final int? dayNumber;
  final int? targetSets;
  final int? targetReps;
  final double? targetWeight; // weight can be decimal
  final int? restTimeSec;
  final int? timePerSetSec;
  final int? order;
  final String? notes;

  WorkoutDayExerciseDto({
    required this.id,
    required this.workoutPlanId,
    required this.workoutDayId,
    required this.exerciseId,
    this.dayNumber,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.restTimeSec,
    this.timePerSetSec,
    this.order,
    this.notes,
  });

  factory WorkoutDayExerciseDto.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) => v is int ? v : (v is double ? v.toInt() : null);
    double? asDouble(dynamic v) =>
        v is int ? v.toDouble() : (v is double ? v : null);
    return WorkoutDayExerciseDto(
      id: json['id'] as String,
      workoutPlanId: json['workoutPlanId'] as String,
      workoutDayId: json['workoutDayId'] as String,
      exerciseId: json['exerciseId'] as String,
      dayNumber: asInt(json['dayNumber']),
      targetSets: asInt(json['targetSets']),
      targetReps: asInt(json['targetReps']),
      targetWeight: asDouble(json['targetWeight']),
      restTimeSec: asInt(json['restTimeSec']),
      timePerSetSec: asInt(json['timePerSetSec']),
      order: asInt(json['order']),
      notes: json['notes'] as String?,
    );
  }
}

class WorkoutDayExercisesRepository {
  Future<List<WorkoutDayExerciseDto>> getByWorkoutDay(
    String workoutDayId,
  ) async {
    final path = '/workout-plans/exercises?workoutDayId=$workoutDayId';
    final res = await ApiClient.instance.get(path);
    if (res == null) throw Exception('Unauthorized');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        final decoded = ApiClient.instance.decodeBody(res);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => WorkoutDayExerciseDto.fromJson(e))
              .toList();
        }
        throw Exception('Unexpected body type');
      } catch (e) {
        throw Exception('Decode error: $e');
      }
    }
    throw Exception('Request failed: ${res.statusCode}');
  }

  /// Lấy tất cả bài tập thuộc một workout plan (query theo workoutPlanId)
  /// Backend hỗ trợ endpoint ví dụ:
  /// GET /workout-plans/exercises?workoutPlanId=PLAN_ID
  Future<List<WorkoutDayExerciseDto>> getByWorkoutPlan(
    String workoutPlanId,
  ) async {
    final path = '/workout-plans/exercises?workoutPlanId=$workoutPlanId';
    final res = await ApiClient.instance.get(path);
    if (res == null) throw Exception('Unauthorized');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        final decoded = ApiClient.instance.decodeBody(res);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => WorkoutDayExerciseDto.fromJson(e))
              .toList();
        }
        throw Exception('Unexpected body type');
      } catch (e) {
        throw Exception('Decode error: $e');
      }
    }
    throw Exception('Request failed: ${res.statusCode}');
  }

  Future<WorkoutDayExerciseDto?> create({
    required String workoutPlanId,
    required String workoutDayId,
    required String exerciseId,
    required int dayNumber,
    int? targetSets,
    int? targetReps,
    num? targetWeight,
    int? restTimeSec,
    int? timePerSetSec,
    int? order,
    String? notes,
  }) async {
    final path = '/workout-plans/exercises';
    final body = <String, dynamic>{
      'workoutPlanId': workoutPlanId,
      'workoutDayId': workoutDayId,
      'exerciseId': exerciseId,
      'dayNumber': dayNumber,
      if (targetSets != null) 'targetSets': targetSets,
      if (targetReps != null) 'targetReps': targetReps,
      if (targetWeight != null) 'targetWeight': targetWeight,
      if (restTimeSec != null) 'restTimeSec': restTimeSec,
      if (timePerSetSec != null) 'timePerSetSec': timePerSetSec,
      if (order != null) 'order': order,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final res = await ApiClient.instance.post(path, body: body);
    if (res == null) throw Exception('Unauthorized');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = ApiClient.instance.decodeBody(res);
      if (decoded is Map<String, dynamic>) {
        return WorkoutDayExerciseDto.fromJson(decoded);
      }
      return null;
    }
    throw Exception('Create failed: ${res.statusCode}');
  }

  Future<WorkoutDayExerciseDto?> update({
    required String id, // id của workout day exercise record
    required String workoutPlanId,
    required String workoutDayId,
    required String exerciseId,
    int? targetSets,
    int? targetReps,
    num? targetWeight,
    int? restTimeSec,
    int? timePerSetSec,
    int? order,
    String? notes,
  }) async {
    final path = '/workout-plans/exercises/$id';
    final body = <String, dynamic>{
      'workoutPlanId': workoutPlanId,
      'workoutDayId': workoutDayId,
      'exerciseId': exerciseId,
      if (targetSets != null) 'targetSets': targetSets,
      if (targetReps != null) 'targetReps': targetReps,
      if (targetWeight != null) 'targetWeight': targetWeight,
      if (restTimeSec != null) 'restTimeSec': restTimeSec,
      if (timePerSetSec != null) 'timePerSetSec': timePerSetSec,
      if (order != null) 'order': order,
      // notes có thể null -> backend lưu null
      'notes': notes,
    };
    final res = await ApiClient.instance.patch(path, body: body);
    if (res == null) throw Exception('Unauthorized');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = ApiClient.instance.decodeBody(res);
      if (decoded is Map<String, dynamic>) {
        return WorkoutDayExerciseDto.fromJson(decoded);
      }
      return null;
    }
    throw Exception('Update failed: ${res.statusCode}');
  }

  Future<bool> delete(String id) async {
    final path = '/workout-plans/exercises/$id';
    final res = await ApiClient.instance.delete(path);
    if (res == null) throw Exception('Unauthorized');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return true; // backend có thể trả body hoặc không; chỉ cần status success
    }
    throw Exception('Delete failed: ${res.statusCode}');
  }
}
