import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/api_service.dart';
import 'core/logging/app_logger.dart';
// Import các màn hình chính của app
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/signup/signup_screen.dart';
import 'screens/auth/signin/signin_screen.dart';
import 'screens/profile_setup/profile_setup_screen.dart';
import 'screens/profile_setup/welcome_profile_setup_screen.dart';
import 'screens/main_screen.dart';

// ==== App Config ==== //
const Duration kTokenRefreshInterval = Duration(
  seconds: 600,
); // thời gian refresh token
const String kAccessTokenKey = 'access_token';
const String kRefreshTokenKey = 'refresh_token';

/// Entry point của ứng dụng
final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();
void main() {
  runApp(MyApp(key: myAppKey));
}

/// Widget gốc của app, quản lý trạng thái khởi động và điều hướng màn hình đầu tiên
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  // Cho phép gọi từ nơi khác để hủy timer refresh token
  void cancelRefreshTimer() {
    _refreshTimer?.cancel();
    AppLogger.info('Đã hủy timer refresh token', tag: 'App');
  }

  Timer? _refreshTimer;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Widget? _home;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Hàm khởi tạo app, kiểm tra trạng thái onboarding, token, và profile user
  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    if (!seenOnboarding) {
      setState(() {
        _home = const OnboardingScreen();
        _loading = false;
      });
      _refreshTimer?.cancel();
      return;
    }
    // Kiểm tra access token
    String? accessToken = prefs.getString(kAccessTokenKey);
    if (accessToken == null) {
      setState(() {
        _home = const WelcomeScreen();
        _loading = false;
      });
      _refreshTimer?.cancel();
      return;
    }
    // Nếu có token, thử gọi API lấy profile
    try {
      var user = await ApiService.getProfile(accessToken);
      // Nếu token hết hạn hoặc lỗi, thử refresh token
      if (user == null) {
        final refreshToken = await _secureStorage.read(key: kRefreshTokenKey);
        if (refreshToken != null) {
          final refreshResult = await ApiService.refreshToken(refreshToken);
          if (refreshResult != null && refreshResult['access_token'] != null) {
            accessToken = refreshResult['access_token'] as String;
            await prefs.setString(kAccessTokenKey, accessToken);
            user = await ApiService.getProfile(accessToken);
          }
        }
      }
      if (user != null) {
        if (user['dateOfBirth'] == null) {
          final userName = user['name'] != null ? user['name'] as String : '';
          setState(() {
            _home = WelcomeProfileSetupScreen(userName: userName);
            _loading = false;
          });
          _refreshTimer?.cancel();
        } else {
          AppLogger.info('Vào MainScreen, bắt đầu refresh token', tag: 'App');
          setState(() {
            _home = const MainScreen();
            _loading = false;
          });
        }
      } else {
        // Token hết hạn hoặc refresh thất bại, xóa token và về màn hình welcome
        await prefs.remove(kAccessTokenKey);
        await _secureStorage.delete(key: kRefreshTokenKey);
        setState(() {
          _home = const WelcomeScreen();
          _loading = false;
        });
        _refreshTimer?.cancel();
      }
    } catch (e) {
      await prefs.remove(kAccessTokenKey);
      await _secureStorage.delete(key: kRefreshTokenKey);
      setState(() {
        _home = const WelcomeScreen();
        _loading = false;
      });
      _refreshTimer?.cancel();
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
