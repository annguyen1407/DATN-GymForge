import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/exercise_model.dart';

class ExercisePerformanceModel {
  final String exerciseId;
  final String exerciseName;
  final int totalSessions;
  final int bestWeight;
  final int bestReps;
  final double averageWeight;
  final double averageReps;
  final double totalCaloriesBurned;
  final String progressTrend; // stable / positive / negative
  final String? lastPerformed; // ISO date (yyyy-MM-dd)

  ExercisePerformanceModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.totalSessions,
    required this.bestWeight,
    required this.bestReps,
    required this.averageWeight,
    required this.averageReps,
    required this.totalCaloriesBurned,
    required this.progressTrend,
    required this.lastPerformed,
  });

  factory ExercisePerformanceModel.fromJson(Map<String, dynamic> json) {
    return ExercisePerformanceModel(
      exerciseId: json['exerciseId'] ?? '',
      exerciseName: json['exerciseName'] ?? '',
      totalSessions: json['totalSessions'] ?? 0,
      bestWeight: json['bestWeight'] ?? 0,
      bestReps: json['bestReps'] ?? 0,
      averageWeight: (json['averageWeight'] is num)
          ? (json['averageWeight'] as num).toDouble()
          : 0,
      averageReps: (json['averageReps'] is num)
          ? (json['averageReps'] as num).toDouble()
          : 0,
      totalCaloriesBurned: (json['totalCaloriesBurned'] is num)
          ? (json['totalCaloriesBurned'] as num).toDouble()
          : 0,
      progressTrend: json['progressTrend'] ?? 'stable',
      lastPerformed: json['lastPerformed'],
    );
  }
}

class ExercisesRepository {
  final _api = ApiClient.instance;
  // Simple in-memory cache for exercise details by id
  final Map<String, ExerciseModel> _cache = {};

  Future<List<ExerciseModel>> getAll() async {
    const path = '/exercises';
    _logReq('GET', path);
    final res = await _api.requestJson('GET', path);
    _logRes(
      'GET',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! List) return [];
    return (res.raw as List)
        .whereType<Map>()
        .map((e) => ExerciseModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<ExerciseModel?> getById(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final path = '/exercises/$id';
    _logReq('GET', path);
    final res = await _api.requestJson('GET', path);
    _logRes(
      'GET',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      final model = ExerciseModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
      _cache[id] = model;
      return model;
    } catch (_) {
      return null;
    }
  }

  Future<List<ExerciseModel>> getByMuscleGroup(String muscleGroupId) async {
    final path = '/exercises/muscle-group/$muscleGroupId';
    _logReq('GET', path);
    final res = await _api.requestJson('GET', path);
    _logRes(
      'GET',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! List) return [];
    return (res.raw as List)
        .whereType<Map>()
        .map((e) => ExerciseModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<ExercisePerformanceModel?> getPerformanceForExercise({
    required String exerciseId,
    required String userId,
  }) async {
    final path = '/exercises/$exerciseId/performance/$userId';
    _logReq('GET', path);
    final res = await _api.requestJson('GET', path);
    _logRes(
      'GET',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! List || (res.raw as List).isEmpty) return null;
    try {
      final first = (res.raw as List).first;
      if (first is Map) {
        return ExercisePerformanceModel.fromJson(first.cast<String, dynamic>());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Logging helpers (minimal)
  void _logReq(String method, String path) {
    if (kDebugMode) debugPrint('[API][REQ] $method $path');
  }

  void _logRes(
    String method,
    String path,
    int status,
    bool ok,
    String? err,
    String? message, {
    dynamic preview,
  }) {
    if (kDebugMode) {
      debugPrint(
        '[API][RES] $method $path status=$status ok=$ok'
        '${err != null ? ' error=$err' : ''}'
        '${message != null ? ' message="${_truncate(message)}"' : ''}'
        '${preview is List ? ' data=List(len=${preview.length})' : ''}',
      );
    }
  }

  String _truncate(String s, {int max = 160}) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}
