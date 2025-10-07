import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class CurrentUserProfile {
  final String id;
  final String role; // COACH | GYMER | ADMIN
  final String? name;
  CurrentUserProfile({required this.id, required this.role, this.name});
  factory CurrentUserProfile.fromJson(Map<String, dynamic> j) =>
      CurrentUserProfile(
        id: j['id'] ?? '',
        role: j['role'] ?? '',
        name: j['name'],
      );
}

class CoachByUserResult {
  final String id; // coach id
  final String userId;
  CoachByUserResult({required this.id, required this.userId});
  factory CoachByUserResult.fromJson(Map<String, dynamic> j) =>
      CoachByUserResult(id: j['id'] ?? '', userId: j['userId'] ?? '');
}

class GymerByUserResult {
  final String id; // gymer id
  final String userId;
  GymerByUserResult({required this.id, required this.userId});
  factory GymerByUserResult.fromJson(Map<String, dynamic> j) =>
      GymerByUserResult(id: j['id'] ?? '', userId: j['userId'] ?? '');
}

class CurrentUserRepository {
  final _api = ApiClient.instance;
  CurrentUserProfile? _cachedProfile;
  Object? _cachedEntity; // CoachByUserResult or GymerByUserResult

  Future<CurrentUserProfile?> fetchProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfile != null) return _cachedProfile;
    final res = await _api.requestJson('GET', '/auth/profile');
    if (!res.ok || res.raw is! Map) return null;
    try {
      final p = CurrentUserProfile.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
      _cachedProfile = p;
      return p;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CurrentUserRepository] profile parse error: $e');
      }
      return null;
    }
  }

  Future<Object?> fetchRoleEntity({bool forceRefresh = false}) async {
    final profile = await fetchProfile(forceRefresh: forceRefresh);
    if (profile == null) return null;
    if (!forceRefresh && _cachedEntity != null) return _cachedEntity;
    if (profile.role == 'COACH') {
      final res = await _api.requestJson('GET', '/coaches/user/${profile.id}');
      if (res.ok && res.raw is Map) {
        try {
          _cachedEntity = CoachByUserResult.fromJson(
            (res.raw as Map).cast<String, dynamic>(),
          );
          return _cachedEntity;
        } catch (_) {}
      }
    } else if (profile.role == 'GYMER') {
      final res = await _api.requestJson('GET', '/gymers/user/${profile.id}');
      if (res.ok && res.raw is Map) {
        try {
          _cachedEntity = GymerByUserResult.fromJson(
            (res.raw as Map).cast<String, dynamic>(),
          );
          return _cachedEntity;
        } catch (_) {}
      }
    }
    return null;
  }
}
