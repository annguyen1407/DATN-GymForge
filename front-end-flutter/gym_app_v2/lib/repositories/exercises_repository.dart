import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/exercise_model.dart';

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
