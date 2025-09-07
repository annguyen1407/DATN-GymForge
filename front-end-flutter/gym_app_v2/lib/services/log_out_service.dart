import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/welcome/welcome_screen.dart';

/// AuthService: Xử lý các chức năng xác thực như đăng xuất, xóa cache, gọi API logout...
class AuthService {
  /// Hàm logout đầy đủ: xóa token, xóa dữ liệu user, gọi API logout nếu cần, xóa cache...
  static Future<void> logout(BuildContext context) async {
    // TODO: Nếu backend có API logout, gọi tại đây (ví dụ: await ApiService.logout();)

    // Xóa toàn bộ dữ liệu lưu trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

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
    }
  }
}
