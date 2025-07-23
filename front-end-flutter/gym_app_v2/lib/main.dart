import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
// Import các màn hình chính của app
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/signup/signup_screen.dart';
import 'screens/auth/signin/signin_screen.dart';
import 'screens/profile_setup/profile_setup_screen.dart';
import 'screens/profile_setup/welcome_profile_setup_screen.dart';
import 'screens/main_screen.dart';

/// Entry point của ứng dụng
void main() {
  runApp(const MyApp());
}

/// Widget gốc của app, quản lý trạng thái khởi động và điều hướng màn hình đầu tiên
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _home;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// Hàm khởi tạo app, kiểm tra trạng thái onboarding, token, và profile user
  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    // Kiểm tra đã xem onboarding chưa
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    if (!seenOnboarding) {
      setState(() {
        _home = const OnboardingScreen();
        _loading = false;
      });
      return;
    }
    // Kiểm tra access token
    final accessToken = prefs.getString('access_token');
    if (accessToken == null) {
      setState(() {
        _home = const WelcomeScreen();
        _loading = false;
      });
      return;
    }
    // Nếu có token, gọi API lấy profile qua ApiService
    try {
      final user = await ApiService.getProfile(accessToken);
      if (user != null) {
        // Nếu chưa setup profile (chưa có ngày sinh), chuyển tới màn hình setup
        if (user['dateOfBirth'] == null) {
          setState(() {
            _home = WelcomeProfileSetupScreen(userName: user['name'] ?? '');
            _loading = false;
          });
        } else {
          // Nếu đã có profile, vào màn hình chính
          setState(() {
            _home = const MainScreen();
            _loading = false;
          });
        }
      } else {
        // Token hết hạn hoặc lỗi, xóa token và về màn hình welcome
        await prefs.remove('access_token');
        setState(() {
          _home = const WelcomeScreen();
          _loading = false;
        });
      }
    } catch (e) {
      // Lỗi mạng hoặc lỗi khác, xóa token và về màn hình welcome
      await prefs.remove('access_token');
      setState(() {
        _home = const WelcomeScreen();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Hiển thị loading khi đang kiểm tra trạng thái, hoặc hiển thị màn hình phù hợp
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _home,
      // Định nghĩa các route cho app
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/main': (context) => const MainScreen(),
        '/welcome-profile-setup': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final userName = args != null && args['userName'] != null
              ? args['userName'] as String
              : '';
          return WelcomeProfileSetupScreen(userName: userName);
        },
      },
    );
  }
}

// ...existing code...
