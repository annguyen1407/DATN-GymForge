import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class GymerDetailModel {
  final String id; // gymer id
  final String userId;
  final String?
  pictureProfile; // dedicated gymer profile picture (if differs from user.profilePicture)
  final Map<String, dynamic>? user; // nested user raw (name/email etc.)
  final double? weight;
  final int? height;
  final String? goal; // optional fitness goal

  GymerDetailModel({
    required this.id,
    required this.userId,
    this.pictureProfile,
    this.user,
    this.weight,
    this.height,
    this.goal,
  });

  factory GymerDetailModel.fromJson(Map<String, dynamic> j) {
    return GymerDetailModel(
      id: j['id'] ?? '',
      userId: j['userId'] ?? '',
      pictureProfile: j['pictureProfile'],
      user: j['user'] is Map
          ? (j['user'] as Map).cast<String, dynamic>()
          : null,
      weight: j['weight'] is num ? (j['weight'] as num).toDouble() : null,
      height: j['height'] is num ? (j['height'] as num).toInt() : null,
      goal: j['goal'] as String?,
    );
  }
}

class GymersRepository {
  final _api = ApiClient.instance;
  final Map<String, GymerDetailModel> _cache = {};
  final Map<String, Future<GymerDetailModel?>> _inFlight = {};

  Future<GymerDetailModel?> fetchByUserId(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId];
    if (_inFlight.containsKey(userId)) return _inFlight[userId];
    final fut = _fetch(userId);
    _inFlight[userId] = fut;
    final res = await fut;
    _inFlight.remove(userId);
    if (res != null) _cache[userId] = res;
    return res;
  }

  Future<GymerDetailModel?> _fetch(String userId) async {
    final path = '/gymers/user/$userId';
    if (kDebugMode) debugPrint('[API][REQ] GET $path');
    final res = await _api.requestJson('GET', path);
    if (!res.ok || res.raw is! Map) return null;
    try {
      return GymerDetailModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GymersRepository] parse error: $e');
      return null;
    }
  }
}
