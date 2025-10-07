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
            (e) => FeedbackModel.fromJson((e).cast<String, dynamic>()),
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

  Future<FeedbackModel?> updateFeedback({
    required String feedbackId,
    required String coachId,
    double? rating,
    String? content,
  }) async {
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (content != null) body['content'] = content;
    if (kDebugMode) {
      debugPrint('[API][REQ] PATCH /feedbacks/$feedbackId body=$body');
    }
    final res = await _api.requestJson(
      'PATCH',
      '/feedbacks/$feedbackId',
      body: body,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      final updated = FeedbackModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
      final list = _cache[coachId];
      if (list != null) {
        final idx = list.indexWhere((f) => f.id == feedbackId);
        if (idx != -1) {
          list[idx] = updated;
          // keep ordering by createdAt (assuming unchanged) else re-sort
        }
      }
      return updated;
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] parse feedback update: $e');
      return null;
    }
  }

  Future<bool> deleteFeedback({
    required String feedbackId,
    required String coachId,
  }) async {
    if (kDebugMode) {
      debugPrint('[API][REQ] DELETE /feedbacks/$feedbackId');
    }
    final res = await _api.requestJson('DELETE', '/feedbacks/$feedbackId');
    if (!res.ok) return false;
    final list = _cache[coachId];
    if (list != null) {
      list.removeWhere((f) => f.id == feedbackId);
    }
    return true;
  }
}
