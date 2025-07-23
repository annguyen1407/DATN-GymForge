import 'dart:convert';
import 'package:http/http.dart' as http;

/// ApiService: Chỉ xử lý logic gọi API, không liên quan UI
class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  /// Đăng nhập, trả về Map chứa access_token và user nếu thành công, null nếu lỗi
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      print('[LOGIN] email: $email, password: $password');
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );
      print('[LOGIN] response status: ${response.statusCode}');
      print('[LOGIN] response body: ${response.body}');
      final body = jsonDecode(response.body);
      return {
        'status': response.statusCode,
        ...((body is Map<String, dynamic>) ? body : {}),
      };
    } catch (e) {
      print('[LOGIN] error: $e');
      return null;
    }
  }

  /// Đăng ký, trả về Map chứa access_token và user nếu thành công, null nếu lỗi
  static Future<Map<String, dynamic>?> signup(Map<String, dynamic> body) async {
    try {
      print('[SIGNUP] body: $body');
      final url = Uri.parse('$baseUrl/auth/register');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      print('[SIGNUP] response status: ${response.statusCode}');
      print('[SIGNUP] response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': response.statusCode,
          'data': jsonDecode(response.body),
        };
      } else {
        return {'status': response.statusCode, 'data': null};
      }
    } catch (e) {
      print('[SIGNUP] error: $e');
      return {'status': -1, 'data': null};
    }
  }
}
