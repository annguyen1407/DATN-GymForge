import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_mapper.dart';
import '../models/workout_plan_model.dart';

class WorkoutPlansRepository {
  final _api = ApiClient.instance;

  Future<List<WorkoutPlanModel>> getPlans({required String userId}) async {
    final path = '/workout-plans?userId=$userId';
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
    if (!res.ok) return [];
    // Response is list
    return res.asModelList(WorkoutPlanModel.fromJson);
  }

  Future<WorkoutPlanModel?> createPlan({
    required String userId,
    required String name,
    String? description,
    String? planType,
    int? days,
    String? picture,
    bool isTemplate = false,
  }) async {
    final body = {
      'userId': userId,
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (planType != null && planType.isNotEmpty) 'planType': planType,
      if (days != null) 'days': days,
      // backend expects explicit status if we want to force ACTIVE
      'status': 'ACTIVE',
      // explicitly send isTemplate false (even though default) for clarity
      'isTemplate': isTemplate, // always false per requirement now
      // picture currently null -> omit if empty
      if (picture != null && picture.isNotEmpty) 'picture': picture,
    };
    const path = '/workout-plans';
    _logReq('POST', path, body: body);
    final res = await _api.requestJson('POST', path, body: body);
    _logRes(
      'POST',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.data == null) return null;
    return WorkoutPlanModel.fromJson(res.data as Map<String, dynamic>);
  }

  // --- Logging Helpers --------------------------------------------------
  void _logReq(String method, String path, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      debugPrint(
        '[API][REQ] $method $path'
        '${body != null ? ' body=' + _compactJson(body) : ''}',
      );
    }
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
      final snippet = _preview(preview);
      debugPrint(
        '[API][RES] $method $path status=$status ok=$ok'
        '${err != null ? ' error=$err' : ''}'
        '${message != null ? ' message="${_truncate(message)}"' : ''}'
        '${snippet != null ? ' data=$snippet' : ''}',
      );
    }
  }

  String? _preview(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is Map) {
        // Prefer showing id & name if present
        final map = <String, dynamic>{};
        for (final k in ['id', 'name', 'planType', 'status']) {
          if (raw.containsKey(k)) map[k] = raw[k];
        }
        if (map.isNotEmpty) return _compactJson(map);
        return _truncate(_compactJson(raw));
      }
      if (raw is List) {
        return 'List(len=${raw.length})';
      }
      return _truncate(raw.toString());
    } catch (_) {
      return null;
    }
  }

  String _compactJson(Object obj) => jsonEncode(obj);
  String _truncate(String s, {int max = 160}) =>
      s.length <= max ? s : s.substring(0, max) + '…';
}
