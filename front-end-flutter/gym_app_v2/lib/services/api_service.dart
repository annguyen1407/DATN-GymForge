import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../core/api/api_client.dart';
import '../core/logging/app_logger.dart';

/// ApiService: Chỉ xử lý logic gọi API, không liên quan UI
class ApiService {
  /// Gọi API logout, truyền access token vào header và refresh token vào body
  static Future<bool> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/logout');
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      return response.statusCode == 200;
    } catch (e, st) {
      AppLogger.error(
        'Logout error: $e',
        tag: 'ApiService',
        stackTrace: st,
        error: e,
      );
      return false;
    }
  }

  /// Refresh access token bằng refresh_token (lấy từ secure storage)
  static Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/refresh');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      final body = jsonDecode(response.body);
      return {
        'status': response.statusCode,
        ...((body is Map<String, dynamic>) ? body : {}),
      };
    } catch (e, st) {
      AppLogger.error(
        'Refresh token error: $e',
        tag: 'ApiService',
        stackTrace: st,
        error: e,
      );
      return null;
    }
  }

  /// Lấy profile user từ access token, trả về Map hoặc null nếu lỗi
  /// NOTE: Hàm này trả về dữ liệu thô (Map), KHÔNG tự động logout nếu token hết hạn (401).
  /// Nếu muốn lấy UserModel và tự động logout khi token hết hạn, dùng UserService.fetchProfile.
  static Future<Map<String, dynamic>?> getProfile(String accessToken) async {
    // Deprecated direct usage; keep backward compatibility by still honoring provided accessToken
    // Prefer: ApiClient.instance.get('/auth/profile')
    try {
      final res = await ApiClient.instance.get('/auth/profile');
      if (res != null && res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Đăng nhập, trả về Map chứa access_token và user nếu thành công, null nếu lỗi
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      AppLogger.info('[LOGIN] email: $email', tag: 'ApiService');
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );
      //print('[LOGIN] response status: ${response.statusCode}');
      // print('[LOGIN] response body: ${response.body}');
      final body = jsonDecode(response.body);
      return {
        'status': response.statusCode,
        ...((body is Map<String, dynamic>) ? body : {}),
      };
    } catch (e, st) {
      AppLogger.error(
        'Login error: $e',
        tag: 'ApiService',
        stackTrace: st,
        error: e,
      );
      return null;
    }
  }

  /// Đăng ký, trả về Map chứa access_token và user nếu thành công, null nếu lỗi
  static Future<Map<String, dynamic>?> signup(Map<String, dynamic> body) async {
    try {
      AppLogger.debug('[SIGNUP] body: $body', tag: 'ApiService');
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/register');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      // print('[SIGNUP] response status: ${response.statusCode}');
      //print('[SIGNUP] response body: ${response.body}');
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Trả về cùng cấu trúc như login
        return {
          'status': response.statusCode,
          ...((resBody is Map<String, dynamic>) ? resBody : {}),
        };
      } else {
        return {
          'status': response.statusCode,
          ...((resBody is Map<String, dynamic>) ? resBody : {}),
        };
      }
    } catch (e, st) {
      AppLogger.error(
        'Signup error: $e',
        tag: 'ApiService',
        stackTrace: st,
        error: e,
      );
      return null;
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

  /// Quên mật khẩu: gửi OTP về email
  static Future<bool> forgotPassword({required String email}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/forgot-password');
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

  /// Đặt lại mật khẩu bằng OTP
  static Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/reset-password');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
