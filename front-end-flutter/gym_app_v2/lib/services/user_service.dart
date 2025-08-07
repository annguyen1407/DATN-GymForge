import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_constants.dart';
import 'auth_service.dart';

class UserService {
  /// Wrapper cho http.get: tự động kiểm tra 401 và logout nếu cần
  static Future<http.Response?> safeGet(
    BuildContext context,
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 401 && context.mounted) {
      await AuthService.logout(context);
      return null;
    }
    return res;
  }

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
