import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_service.dart';
import '../../services/log_out_service.dart';
import '../../main.dart' show kTokenRefreshInterval;
import 'package:flutter/material.dart';
import '../core/logging/app_logger.dart';
import 'user/user_screen.dart';
import 'home/home_screen.dart';
import 'workout/workout_screen.dart';
import 'exercise/exercise_screen.dart';
import 'log/log_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

/// MainScreen: Màn hình chính chứa 5 tab (Home, Workout, Exercise, Log, User)
/// Quản lý trạng thái tab hiện tại và truyền dữ liệu user cho các tab cần thiết
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Timer? _refreshTimer;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  int _selectedIndex = 0; // Tab hiện tại
  UserModel? _user; // Thông tin user lấy từ API
  bool _loading = true; // Trạng thái loading khi fetch user

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _startPeriodicTokenRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicTokenRefresh() {
    AppLogger.info('Khởi động timer refresh token', tag: 'MainScreen');
    _refreshTimer = Timer.periodic(kTokenRefreshInterval, (_) async {
      AppLogger.debug(
        'Thực hiện refresh token lúc ${DateTime.now()}',
        tag: 'MainScreen',
      );
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        final refreshResult = await ApiService.refreshToken(refreshToken);
        if (refreshResult != null &&
            refreshResult['access_token'] != null &&
            refreshResult['refresh_token'] != null) {
          accessToken = refreshResult['access_token'] as String;
          await prefs.setString('access_token', accessToken);
          await _secureStorage.write(
            key: 'refresh_token',
            value: refreshResult['refresh_token'] as String,
          );
        } else {
          // Nếu refresh thất bại, tự động logout
          _refreshTimer?.cancel();
          if (mounted) await LogoutService.logout(context);
        }
      }
    });
  }

  /// Gọi API lấy profile user
  Future<void> _fetchUser() async {
    final user = await UserService.fetchProfile(context);
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  /// Đổi tab khi bấm bottom nav
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Hiển thị loading khi đang lấy user
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Danh sách các tab chính
    final List<Widget> tabs = [
      HomeScreen(userName: _user?.name ?? ''),
      WorkoutScreen(),
      ExerciseScreen(),
      LogScreen(),
      UserScreen(),
    ];
    return Scaffold(
      body: tabs[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
