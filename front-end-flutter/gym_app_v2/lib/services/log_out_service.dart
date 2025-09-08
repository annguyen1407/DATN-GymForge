import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../screens/welcome/welcome_screen.dart';
import 'api_service.dart';
import '../main.dart' show myAppKey;

/// LogoutService: Chỉ xử lý chức năng đăng xuất, xóa cache, điều hướng về màn hình welcome
class LogoutService {
  /// Hàm logout đầy đủ: xóa token, xóa dữ liệu user, gọi API logout nếu cần, xóa cache...
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = const FlutterSecureStorage();
    final accessToken = prefs.getString('access_token');
    final refreshToken = await secureStorage.read(key: 'refresh_token');

    // Gọi API logout nếu có đủ token
    if (accessToken != null && refreshToken != null) {
      await ApiService.logout(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    // Xóa toàn bộ dữ liệu lưu trong SharedPreferences
    await prefs.clear();
    await secureStorage.delete(key: 'refresh_token');

    // TODO: Xóa cache, database local, ảnh... nếu app có sử dụng

    // Điều hướng về màn hình welcome/login
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
      // Hủy timer refresh token toàn cục
      myAppKey.currentState?.cancelRefreshTimer();
    }
  }
}
