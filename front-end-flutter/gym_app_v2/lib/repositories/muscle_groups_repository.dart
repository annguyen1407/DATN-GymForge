import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/muscle_group_model.dart';

class MuscleGroupsRepository {
  final _api = ApiClient.instance;

  Future<List<MuscleGroupModel>> getMuscleGroups() async {
    const path = '/muscle-groups';
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
        .map((e) => MuscleGroupModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  void _logReq(String method, String path, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      debugPrint(
        '[API][REQ] $method $path${body != null ? ' body=' + jsonEncode(body) : ''}',
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
      if (raw is List) return 'List(len=${raw.length})';
      if (raw is Map) {
        final map = <String, dynamic>{};
        for (final k in ['id', 'name']) {
          if (raw.containsKey(k)) map[k] = raw[k];
        }
        if (map.isNotEmpty) return jsonEncode(map);
        return _truncate(jsonEncode(raw));
      }
      return _truncate(raw.toString());
    } catch (_) {
      return null;
    }
  }

  String _truncate(String s, {int max = 160}) =>
      s.length <= max ? s : s.substring(0, max) + '…';
}
