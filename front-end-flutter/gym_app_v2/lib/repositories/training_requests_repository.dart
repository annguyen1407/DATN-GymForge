import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class TrainingRequestModel {
  final String id;
  final String status; // PENDING / ACCEPTED / REJECTED
  final String gymerId;
  final String coachId;
  TrainingRequestModel({
    required this.id,
    required this.status,
    required this.gymerId,
    required this.coachId,
  });
  factory TrainingRequestModel.fromJson(Map<String, dynamic> j) =>
      TrainingRequestModel(
        id: j['id'] ?? '',
        status: j['status'] ?? '',
        gymerId: j['gymerId'] ?? '',
        coachId: j['coachId'] ?? '',
      );
}

class TrainingRequestsRepository {
  final _api = ApiClient.instance;

  Future<List<TrainingRequestModel>> fetch({
    required String gymerId,
    required String coachId,
  }) async {
    final path = '/training-requests?gymerId=$gymerId&coachId=$coachId';
    if (kDebugMode) debugPrint('[API][REQ] GET $path');
    final res = await _api.requestJson('GET', path);
    if (!res.ok || res.raw is! List) return [];
    try {
      return (res.raw as List)
          .whereType<Map>()
          .map((e) => TrainingRequestModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] training-requests parse: $e');
      return [];
    }
  }

  Future<bool> hasAnyAcceptedElsewhere({required String gymerId}) async {
    // status=ACCEPTED (do not filter by coach so we know if already under contract with someone)
    final path = '/training-requests?gymerId=$gymerId&status=ACCEPTED';
    if (kDebugMode) debugPrint('[API][REQ] GET $path');
    final res = await _api.requestJson('GET', path);
    if (!res.ok || res.raw is! List) return false;
    try {
      final list = (res.raw as List);
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<TrainingRequestModel?> create({
    required String gymerId,
    required String coachId,
    required DateTime trainingDate,
  }) async {
    final body = {
      'gymerId': gymerId,
      'coachId': coachId,
      'trainingDate': trainingDate.toUtc().toIso8601String(),
    };
    if (kDebugMode) debugPrint('[API][REQ] POST /training-requests body=$body');
    final res = await _api.requestJson(
      'POST',
      '/training-requests',
      body: body,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      return TrainingRequestModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      if (kDebugMode)
        debugPrint('[API][ERR] training-requests create parse: $e');
      return null;
    }
  }
}
