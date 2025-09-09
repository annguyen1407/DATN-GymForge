import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_constants.dart';
import 'log_out_service.dart';

class UserService {
  /// Wrapper cho http.patch: tự động kiểm tra 401 và logout nếu cần
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return false;
    final res = await safePatch(
      context,
      Uri.parse('${ApiConstants.baseUrl}/profile'),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (res != null && res.statusCode == 200) {
      return true;
    }
    return false;
  }

  /// Wrapper cho http.get: tự động kiểm tra 401 và logout nếu cần
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;
    final res = await safeGet(
      context,
      Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    if (res != null && res.statusCode == 200) {
      final data = json.decode(res.body);
      return UserModel.fromJson(data);
    }
    return null;
  }
}
