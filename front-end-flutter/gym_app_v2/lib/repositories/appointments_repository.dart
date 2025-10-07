import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class AppointmentModel {
  final String id;
  final DateTime? date; // may be null per backend create logic
  final String status; // PENDING / CONFIRMED / COMPLETED / CANCELLED
  final String coachId;
  final String gymerId;
  final CoachInfo? coach;
  final GymerInfo? gymer;
  final String?
  note; // optional client-side extension (may be absent in backend)
  final String?
  location; // optional location / meeting place (backend field 'location')

  AppointmentModel({
    required this.id,
    required this.date,
    required this.status,
    required this.coachId,
    required this.gymerId,
    this.coach,
    this.gymer,
    this.note,
    this.location,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) => AppointmentModel(
    id: j['id'] ?? '',
    date: j['date'] != null ? DateTime.tryParse(j['date'])?.toLocal() : null,
    status: j['status'] ?? '',
    coachId: j['coachId'] ?? '',
    gymerId: j['gymerId'] ?? '',
    coach: j['coach'] != null ? CoachInfo.fromJson(j['coach']) : null,
    gymer: j['gymer'] != null ? GymerInfo.fromJson(j['gymer']) : null,
    note: j['note'],
    location:
        j['location'] ??
        j['address'], // fallback hỗ trợ version cũ nếu backend từng dùng 'address'
  );
}

class CoachInfo {
  final String id;
  final UserInfo? user;

  CoachInfo({required this.id, this.user});

  factory CoachInfo.fromJson(Map<String, dynamic> j) => CoachInfo(
    id: j['id'] ?? '',
    user: j['user'] != null ? UserInfo.fromJson(j['user']) : null,
  );
}

class GymerInfo {
  final String id;
  final UserInfo? user;

  GymerInfo({required this.id, this.user});

  factory GymerInfo.fromJson(Map<String, dynamic> j) => GymerInfo(
    id: j['id'] ?? '',
    user: j['user'] != null ? UserInfo.fromJson(j['user']) : null,
  );
}

class UserInfo {
  final String id;
  final String name;
  final String? profilePicture;

  UserInfo({required this.id, required this.name, this.profilePicture});

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    profilePicture: j['profilePicture'],
  );
}

class AppointmentsRepository {
  final _api = ApiClient.instance;

  Future<List<AppointmentModel>> fetchConfirmedByCoach(String coachId) async {
    final path = '/appointments?coachId=$coachId&status=CONFIRMED';
    if (kDebugMode) debugPrint('[API][REQ] GET $path');
    final res = await _api.requestJson('GET', path);
    if (!res.ok || res.raw is! List) return [];
    try {
      return (res.raw as List)
          .whereType<Map>()
          .map((e) => AppointmentModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] appointments parse: $e');
      return [];
    }
  }

  Future<AppointmentModel?> create({
    required String gymerId,
    required String coachId,
    required DateTime date,
    String? note,
    String? location,
  }) async {
    final body = {
      'gymerId': gymerId,
      'coachId': coachId,
      'date': date.toUtc().toIso8601String(),
    };
    if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();
    if (location != null && location.trim().isNotEmpty) {
      body['location'] = location.trim();
    }
    if (kDebugMode) debugPrint('[API][REQ] POST /appointments body=$body');
    final res = await _api.requestJson('POST', '/appointments', body: body);
    if (!res.ok || res.raw is! Map) return null;
    try {
      return AppointmentModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] appointments create parse: $e');
      return null;
    }
  }

  Future<List<AppointmentModel>> fetchByGymer(String gymerId) async {
    final path = '/appointments?gymerId=$gymerId';
    if (kDebugMode) debugPrint('[API][REQ] GET $path');
    final res = await _api.requestJson('GET', path);
    if (!res.ok || res.raw is! List) return [];
    try {
      return (res.raw as List)
          .whereType<Map>()
          .map((e) => AppointmentModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] appointments by gymer parse: $e');
      return [];
    }
  }

  Future<List<AppointmentModel>> fetchByCoach(String coachId) async {
    final path = '/appointments?coachId=$coachId';
    if (kDebugMode) debugPrint('[API][REQ] GET $path');
    final res = await _api.requestJson('GET', path);
    if (!res.ok || res.raw is! List) return [];
    try {
      return (res.raw as List)
          .whereType<Map>()
          .map((e) => AppointmentModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] appointments by coach parse: $e');
      return [];
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    final path = '/appointments/$appointmentId/cancel';
    if (kDebugMode) debugPrint('[API][REQ] POST $path');
    final res = await _api.requestJson('POST', path);
    return res.ok;
  }

  Future<bool> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
  ) async {
    final body = {'date': newDate.toUtc().toIso8601String()};
    final path = '/appointments/$appointmentId/reschedule';
    if (kDebugMode) debugPrint('[API][REQ] PUT $path body=$body');
    final res = await _api.requestJson('PUT', path, body: body);
    return res.ok;
  }

  Future<AppointmentModel?> fetchDetail(String appointmentId) async {
    final path = '/appointments/$appointmentId';
    if (kDebugMode) debugPrint('[API][REQ] GET $path');
    final res = await _api.requestJson('GET', path);
    if (!res.ok || res.raw is! Map) return null;
    try {
      return AppointmentModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] appointment detail parse: $e');
      return null;
    }
  }

  // Cập nhật lịch hẹn: có thể truyền 1 hoặc nhiều trường.
  Future<AppointmentModel?> updateAppointment(
    String appointmentId, {
    DateTime? date,
    String? note,
    String? location,
  }) async {
    final body = <String, dynamic>{};
    if (date != null) body['date'] = date.toUtc().toIso8601String();
    if (note != null) body['note'] = note;
    if (location != null) body['location'] = location;
    if (kDebugMode) {
      debugPrint('[API][REQ] PATCH /appointments/$appointmentId body=$body');
    }
    final res = await _api.requestJson(
      'PATCH',
      '/appointments/$appointmentId',
      body: body,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      return AppointmentModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[API][ERR] appointment update parse: $e');
      return null;
    }
  }

  Future<AppointmentModel?> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    final body = {'status': status};
    if (kDebugMode) {
      debugPrint('[API][REQ] PATCH /appointments/$appointmentId body=$body');
    }
    final res = await _api.requestJson(
      'PATCH',
      '/appointments/$appointmentId',
      body: body,
    );
    if (!res.ok || res.raw is! Map) return null;
    try {
      return AppointmentModel.fromJson(
        (res.raw as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API][ERR] appointment status update parse: $e');
      }
      return null;
    }
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    final path = '/appointments/$appointmentId';
    if (kDebugMode) debugPrint('[API][REQ] DELETE $path');
    final res = await _api.requestJson('DELETE', path);
    return res.ok;
  }
}
