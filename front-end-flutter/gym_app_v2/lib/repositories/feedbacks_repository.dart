import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/feedback_model.dart';

class FeedbacksRepository {
  final _api = ApiClient.instance;
  final Map<String, List<FeedbackModel>> _cache = {}; // key = coachId

  Future<List<FeedbackModel>> fetchByCoach(
    String coachId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(coachId)) return _cache[coachId]!;
    final path = '/feedbacks?coachId=$coachId';
    if (kDebugMode) debugPrint('[API][REQ] GET $path');
    final res = await _api.requestJson('GET', path);
    if (kDebugMode) {
      debugPrint('[API][RES] GET $path status=${res.status} ok=${res.ok}');
    }
    if (!res.ok || res.raw is! List) return [];
    try {
      final list = (res.raw as List)
          .whereType<Map>()
          .map(
            (e) => FeedbackModel.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList();
      // sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _cache[coachId] = list;
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<FeedbackModel?> createFeedback({
    required String gymerId,
    required String coachId,
    required double rating,
    required String content,
  }) async {
    final body = {
      'gymerId': gymerId,
      'coachId': coachId,
      'rating': rating,
      'content': content,
    };
    if (kDebugMode) debugPrint('[API][REQ] POST /feedbacks body=$body');
    final res = await _api.requestJson('POST', '/feedbacks', body: body);
    if (!res.ok || res.raw is! Map) return null;
    try {
      final model = FeedbackModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
      // Update cache optimistically
      final list = _cache[coachId];
      if (list != null) {
        list.insert(0, model); // newest first
      } else {
        _cache[coachId] = [model];
      }
      return model;
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] parse feedback create: $e');
      return null;
    }
  }
}
