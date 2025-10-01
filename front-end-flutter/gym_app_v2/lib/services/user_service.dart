import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'log_out_service.dart'; // still used for fatal flows older callers
import '../core/auth/token_manager.dart';
import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../core/api/api_mapper.dart';
import '../core/auth/session_guard.dart';

class UserService {
  /// Wrapper cho http.patch: tự động kiểm tra 401 và logout nếu cần
  @Deprecated('Use ApiClient.instance.patch + TokenManager instead')
  static Future<http.Response?> safePatch(
    BuildContext context,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final res = await http.patch(url, headers: headers, body: body);
    if (res.statusCode == 401 && context.mounted) {
      await LogoutService.logout(context);
      return null;
    }
    return res;
  }

  /// Cập nhật profile user, trả về true nếu thành công, false nếu lỗi hoặc bị logout.
  static Future<bool> updateProfile(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final token = await TokenManager.instance.getValidAccessToken();
    if (token == null) {
      // thử explicit refresh trước khi bỏ cuộc
      final outcome = await TokenManager.instance.forceRefresh();
      if (!outcome.ok) {
        if (context.mounted) {
          await LogoutService.logout(
            context,
            reason: 'no_token_update_profile_fatal',
          );
        }
        return false;
      }
    }
    final res = await ApiClient.instance.patch(
      '/profile',
      body: jsonEncode(data),
    );
    if (res == null) return false; // unauthorized (no token) path
    if (res.statusCode == 401) {
      final decision = await SessionGuard.handlePersistent401(
        context: context,
        source: 'updateProfile',
      );
      if (decision == UnauthorizedResolution.logout) return false;
      // softFail hoặc none => không tự logout, trả về false để UI xử lý
      return false;
    }
    return res.statusCode == 200;
  }

  /// Wrapper cho http.get: tự động kiểm tra 401 và logout nếu cần
  @Deprecated('Use ApiClient.instance.get + TokenManager instead')
  static Future<http.Response?> safeGet(
    BuildContext context,
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 401 && context.mounted) {
      await LogoutService.logout(context);
      return null;
    }
    return res;
  }

  /// Lấy profile user, trả về UserModel hoặc null nếu lỗi.
  /// NOTE: Hàm này sẽ tự động logout nếu token hết hạn (401).
  /// Nếu chỉ muốn lấy dữ liệu thô (Map) và không logout, dùng ApiService.getProfile.
  static Future<UserModel?> fetchProfile(BuildContext context) async {
    var token = await TokenManager.instance.getValidAccessToken();
    if (token == null) {
      final outcome = await TokenManager.instance.forceRefresh();
      if (!outcome.ok) {
        if (context.mounted) {
          await LogoutService.logout(
            context,
            reason: 'no_token_fetch_profile_fatal',
          );
        }
        return null;
      }
      token = outcome.pair?.accessToken; // refresh ok
    }
    final response = await ApiClient.instance.requestJson(
      'GET',
      '/auth/profile',
    );
    final user = response.asModel(UserModel.fromJson);
    if (user != null) return user;
    if (response.error == ApiErrorType.unauthorized) {
      final decision = await SessionGuard.handlePersistent401(
        context: context,
        source: 'fetchProfile',
      );
      if (decision == UnauthorizedResolution.logout) return null;
      return null; // softFail/none: caller thấy null
    }
    return null;
  }
}
