/// launch_helper.dart
/// Dùng để kiểm tra xem app có đang mở lần đầu không
library;

import 'package:shared_preferences/shared_preferences.dart';

class LaunchHelper {
  static const _firstLaunchKey = 'is_first_launch';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_firstLaunchKey);
    return isFirst == null || isFirst == true;
  }

  static Future<void> setLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }
}
