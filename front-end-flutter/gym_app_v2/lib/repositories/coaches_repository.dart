import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/coach_model.dart';

class CoachesQuery {
  final String? sortBy; // price | rating | name | recommended
  final String? sortOrder; // asc | desc
  final bool? isOpenToTraining;
  final double? minPrice;
  final double? maxPrice;

  const CoachesQuery({
    this.sortBy,
    this.sortOrder,
    this.isOpenToTraining,
    this.minPrice,
    this.maxPrice,
  });

  Map<String, String> toQueryParams() {
    final map = <String, String>{};
    if (sortBy != null) map['sortBy'] = sortBy!;
    if (sortOrder != null) map['sortOrder'] = sortOrder!;
    if (isOpenToTraining != null) {
      map['isOpenToTraining'] = isOpenToTraining!.toString();
    }
    if (minPrice != null) map['minPrice'] = minPrice!.toString();
    if (maxPrice != null) map['maxPrice'] = maxPrice!.toString();
    return map;
  }
}

class CoachesRepository {
  final _api = ApiClient.instance;
  // Simple cache (keyed by serialized query)
  final Map<String, List<CoachModel>> _cache = {};
  final Map<String, CoachModel> _byIdCache = {};

  String _key(CoachesQuery q) =>
      q.toQueryParams().entries.map((e) => '${e.key}=${e.value}').join('&');

  Future<List<CoachModel>> fetch(
    CoachesQuery query, {
    bool forceRefresh = false,
  }) async {
    final key = _key(query);
    if (!forceRefresh && _cache.containsKey(key)) return _cache[key]!;

    final qp = query.toQueryParams();
    final qs = qp.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final path = '/coaches${qs.isNotEmpty ? '?$qs' : ''}';
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
    try {
      final list = (res.raw as List)
          .whereType<Map>()
          .map((e) => CoachModel.fromJson((e).cast<String, dynamic>()))
          .toList();
      _cache[key] = list;
      return list;
    } catch (_) {
      return [];
    }
  }

  void _logReq(String method, String path) {
    if (kDebugMode) debugPrint('[API][REQ] $method $path');
  }

  Future<CoachModel?> fetchById(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _byIdCache.containsKey(id)) return _byIdCache[id];
    final path = '/coaches/$id';
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
      final model = CoachModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
      _byIdCache[id] = model;
      return model;
    } catch (_) {
      return null;
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
