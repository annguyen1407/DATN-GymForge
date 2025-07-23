import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_constants.dart';

class UserService {
  static Future<UserModel?> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return UserModel.fromJson(data);
    }
    return null;
  }
}
