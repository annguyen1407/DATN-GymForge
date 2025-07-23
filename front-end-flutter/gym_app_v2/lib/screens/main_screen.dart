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
  UserModel? _user; // Thông tin user lấy từ API
  bool _loading = true; // Trạng thái loading khi fetch user

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  /// Gọi API lấy profile user
  Future<void> _fetchUser() async {
    final user = await UserService.fetchProfile();
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
      UserScreen(userName: _user?.name ?? ''),
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
