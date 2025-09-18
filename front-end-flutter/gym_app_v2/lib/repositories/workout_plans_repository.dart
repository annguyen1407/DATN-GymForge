import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_mapper.dart';
import '../models/workout_plan_model.dart';

// Simple model for a workout plan day (minimal fields for now)
class WorkoutDayModel {
  final String id;
  final String workoutPlanId;
  final int? dayNumber; // may be null if backend allows
  final DateTime? date;

  WorkoutDayModel({
    required this.id,
    required this.workoutPlanId,
    this.dayNumber,
    this.date,
  });

  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) {
    return WorkoutDayModel(
      id: json['id'] as String,
      workoutPlanId: json['workoutPlanId'] as String,
      dayNumber: json['dayNumber'] as int?,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    );
  }
}

class WorkoutPlansRepository {
  final _api = ApiClient.instance;

  // Repurposed: now returns ONLY template plans (isTemplate == true) for expert usage.
  // Previously: required userId and returned user-specific plans.
  Future<List<WorkoutPlanModel>> getPlans() async {
    const path = '/workout-plans';
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
    final all = res.asModelList(WorkoutPlanModel.fromJson);
    return all.where((p) => p.isTemplate).toList();
  }

  /// Clone a template workout plan for a user.
  /// Endpoint: POST /workout-plans/clone-template/{templateId}
  /// Body: { userId, name, description }
  Future<WorkoutPlanModel?> cloneTemplate({
    required String templateId,
    required String userId,
    required String name,
    required String description,
  }) async {
    final path = '/workout-plans/clone-template/$templateId';
    final body = {'userId': userId, 'name': name, 'description': description};
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
    if (!res.ok || res.raw is! Map) return null;
    try {
      return WorkoutPlanModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  // New explicit template endpoint supporting optional planType filter
  Future<List<WorkoutPlanModel>> getTemplatePlans({String? planType}) async {
    final query = (planType != null && planType.isNotEmpty)
        ? '?planType=$planType'
        : '';
    final path = '/workout-plans/templates$query';
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
    return res.asModelList(WorkoutPlanModel.fromJson);
  }

  /// New endpoint variant: GET /workout-plans/user/{userId}
  Future<List<WorkoutPlanModel>> getPlansByUser(String userId) async {
    final path = '/workout-plans/user/$userId';
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

  /// Fetch a single workout plan by id (detail)
  Future<WorkoutPlanModel?> getPlan(String planId) async {
    final path = '/workout-plans/$planId';
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
      return WorkoutPlanModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Update an existing workout plan (partial update allowed).
  /// Only provided (non-null & non-empty) fields will be sent.
  Future<WorkoutPlanModel?> updatePlan(
    String planId, {
    String? name,
    String? description,
    String? planType,
    String? picture,
    String? status, // e.g. ACTIVE, ARCHIVED
    bool? isTemplate,
  }) async {
    final body = <String, dynamic>{
      if (name != null && name.isNotEmpty) 'name': name,
      if (description != null) 'description': description,
      if (planType != null && planType.isNotEmpty) 'planType': planType,
      if (picture != null) 'picture': picture,
      if (status != null && status.isNotEmpty) 'status': status,
      if (isTemplate != null) 'isTemplate': isTemplate,
    };
    if (body.isEmpty) return null; // nothing to patch
    final path = '/workout-plans/$planId';
    _logReq('PATCH', path, body: body);
    final res = await _api.requestJson('PATCH', path, body: body);
    _logRes(
      'PATCH',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      return WorkoutPlanModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------------------
  // Plan Days APIs
  // ----------------------------------------------------------------------
  Future<List<WorkoutDayModel>> getPlanDays(String planId) async {
    final path = '/workout-plans/$planId/days';
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
    final list = (res.raw as List)
        .whereType<Map>()
        .map((e) => WorkoutDayModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    return list;
  }

  Future<WorkoutDayModel?> createDay(
    String planId, {
    int? dayNumber,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{
      if (dayNumber != null) 'dayNumber': dayNumber,
      if (date != null) 'date': date.toIso8601String().split('T').first,
    };
    final path = '/workout-plans/$planId/days';
    _logReq('POST', path, body: body);
    final res = await _api.requestJson(
      'POST',
      path,
      body: body.isEmpty ? {} : body,
    );
    _logRes(
      'POST',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! Map) return null;
    return WorkoutDayModel.fromJson((res.raw as Map).cast<String, dynamic>());
  }

  /// Delete a workout plan by id.
  ///
  /// Backend now returns the deleted plan JSON (or an error). We parse and
  /// return the deleted [WorkoutPlanModel] so callers can show richer UX
  /// (e.g. include the deleted plan name). Returns null on failure.
  Future<WorkoutPlanModel?> deletePlan(String planId) async {
    final path = '/workout-plans/$planId';
    _logReq('DELETE', path);
    final res = await _api.requestJson('DELETE', path);
    _logRes(
      'DELETE',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      return WorkoutPlanModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API][PARSE][deletePlan] Failed to parse deleted plan: $e');
      }
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Day mutation helpers (PATCH / DELETE)
  // ------------------------------------------------------------------
  Future<WorkoutDayModel?> updateDay(
    String dayId, {
    required String workoutPlanId,
    DateTime? date,
    int? dayNumber,
  }) async {
    final body = <String, dynamic>{
      'workoutPlanId': workoutPlanId,
      if (date != null) 'date': date.toIso8601String().split('T').first,
      if (dayNumber != null) 'dayNumber': dayNumber,
    };
    final path = '/workout-plans/days/$dayId';
    _logReq('PATCH', path, body: body);
    final res = await _api.requestJson('PATCH', path, body: body);
    _logRes(
      'PATCH',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      return WorkoutDayModel.fromJson((res.raw as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<WorkoutDayModel?> deleteDay(String dayId) async {
    final path = '/workout-plans/days/$dayId';
    _logReq('DELETE', path);
    final res = await _api.requestJson('DELETE', path);
    _logRes(
      'DELETE',
      path,
      res.status,
      res.ok,
      res.error?.name,
      res.message,
      preview: res.raw,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      return WorkoutDayModel.fromJson((res.raw as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  // --- Logging Helpers --------------------------------------------------
  void _logReq(String method, String path, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      debugPrint(
        '[API][REQ] $method $path'
        '${body != null ? ' body=${_compactJson(body)}' : ''}',
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
      s.length <= max ? s : '${s.substring(0, max)}…';
}
