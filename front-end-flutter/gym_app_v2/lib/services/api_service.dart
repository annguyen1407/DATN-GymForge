import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

/// ApiService: Chỉ xử lý logic gọi API, không liên quan UI
class ApiService {
  /// Lấy profile user từ access token, trả về Map hoặc null nếu lỗi
  static Future<Map<String, dynamic>?> getProfile(String accessToken) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $accessToken'},
      );
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Đăng nhập, trả về Map chứa access_token và user nếu thành công, null nếu lỗi
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      print('[LOGIN] email: $email, password: $password');
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');
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
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/register');
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

  /// Xác thực OTP email
  static Future<bool> verifyEmailOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/verify-email');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Gửi lại mã xác thực email
  static Future<bool> resendVerificationOTP({required String email}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/resend-verification');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
