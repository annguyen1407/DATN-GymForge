import 'package:flutter/material.dart';
import 'user/user_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final user = await UserService.fetchProfile();
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final List<Widget> tabs = [
      Center(child: Text('Homepage', style: TextStyle(fontSize: 24))),
      Center(child: Text('Workout', style: TextStyle(fontSize: 24))),
      Center(child: Text('Exercise', style: TextStyle(fontSize: 24))),
      Center(child: Text('Log', style: TextStyle(fontSize: 24))),
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
