import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../screens/welcome/welcome_screen.dart';
import 'api_service.dart';
import '../core/logging/app_logger.dart';
import '../core/auth/refresh_scheduler.dart';

/// LogoutService: Chỉ xử lý chức năng đăng xuất, xóa cache, điều hướng về màn hình welcome
class LogoutService {
  static bool _isLoggingOut = false;

  /// Hàm logout: hủy phiên, xóa token, điều hướng về màn hình welcome.
  /// [reason] giúp logging/tracking (vd: fatal_refresh, unauthorized_api, user_action,...)
  static Future<void> logout(BuildContext context, {String? reason}) async {
    if (_isLoggingOut) {
      AppLogger.debug('Logout skipped (already in progress) reason=$reason');
      return;
    }
    _isLoggingOut = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = const FlutterSecureStorage();
      final accessToken = prefs.getString('access_token');
      final refreshToken = await secureStorage.read(key: 'refresh_token');

      if (accessToken != null && refreshToken != null) {
        await ApiService.logout(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      // Chỉ xóa key auth, giữ lại các flag như seenOnboarding
      await prefs.remove('access_token');
      // (Nếu có key khác cho user info cache thì remove thêm ở đây)
      await secureStorage.delete(key: 'refresh_token');

      AppLogger.info('Logout done reason=${reason ?? 'n/a'}', tag: 'Logout');

      // Stop global refresh scheduler
      RefreshScheduler.instance.stop();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondary) =>
                const WelcomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (route) => false,
        );
      }
    } catch (e, st) {
      AppLogger.error(
        'Logout exception: $e',
        tag: 'Logout',
        stackTrace: st,
        error: e,
      );
    } finally {
      _isLoggingOut = false;
    }
  }
}
