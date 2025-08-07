import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../utils/token_storage.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await TokenStorage.saveToken(data['access_token']);
      return true;
    }
    return false;
  }

  Future<bool> register(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await TokenStorage.saveToken(data['access_token']);
      return true;
    }
    return false;
  }
}
