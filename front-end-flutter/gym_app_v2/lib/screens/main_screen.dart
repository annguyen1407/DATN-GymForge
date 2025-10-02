// Removed per-screen token refresh timer in favor of global RefreshScheduler started post-login.
import 'package:flutter/material.dart';
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
  int _selectedIndex = 0; // Tab hiện tại
  int _workoutInitialTab = 0; // 0: Khám phá, 1: Kế hoạch, 2: Chuyên gia
  UserModel? _user; // Thông tin user lấy từ API
  bool _loading = true; // Trạng thái loading khi fetch user

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void dispose() {
    super.dispose();
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
    final List<Widget> tabs = [
      HomeScreen(
        userName: _user?.name ?? '',
        isLoading: _loading,
        openWorkoutTab: () {
          setState(() {
            _workoutInitialTab = 0;
            _selectedIndex = 1;
          });
        },
        openWorkoutPlanTab: () {
          setState(() {
            _workoutInitialTab = 1;
            _selectedIndex = 1;
          });
        },
      ),
      WorkoutScreen(
        key: ValueKey('workout-$_workoutInitialTab'),
        initialTabIndex: _workoutInitialTab,
      ),
      const ExerciseScreen(),
      const LogScreen(),
      const UserScreen(),
    ];

    void handleTap(int index) {
      if (_loading && index != 0) return; // lock other tabs until user loaded
      _onItemTapped(index);
    }

    return Scaffold(
      extendBody: true,
      body: tabs[_selectedIndex],
      bottomNavigationBar: Opacity(
        opacity: _loading ? 0.8 : 1,
        child: IgnorePointer(
          ignoring: _loading && _selectedIndex != 0,
          child: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onTap: handleTap,
          ),
        ),
      ),
    );
  }
}
