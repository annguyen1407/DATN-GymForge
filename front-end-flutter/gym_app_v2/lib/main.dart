import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/api_service.dart'; // still used for login/logout flows
import 'core/auth/token_manager.dart';
import 'core/logging/app_logger.dart';
// Import các màn hình chính của app
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/signup/signup_screen.dart';
import 'screens/auth/signin/signin_screen.dart';
import 'screens/profile_setup/profile_setup_screen.dart';
import 'screens/profile_setup/welcome_profile_setup_screen.dart';
import 'screens/main_screen.dart';
import 'core/auth/refresh_scheduler.dart';

// ==== App Config ==== //
const String kAccessTokenKey = 'access_token';
const String kRefreshTokenKey = 'refresh_token';

/// Entry point của ứng dụng
final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // If .env missing we just continue with defaults; ApiConstants has fallback.
    AppLogger.warn('Failed to load .env: $e', tag: 'Env');
  }
  // Optional: override refresh interval via env (seconds)
  final rawInterval = dotenv.env['REFRESH_INTERVAL_SECONDS'];
  if (rawInterval != null && rawInterval.trim().isNotEmpty) {
    final seconds = int.tryParse(rawInterval.trim());
    if (seconds != null && seconds > 0) {
      RefreshScheduler.instance.interval = Duration(seconds: seconds);
      AppLogger.info(
        'Refresh interval overridden from env: ${seconds}s',
        tag: 'Env',
      );
    } else {
      AppLogger.warn(
        'Invalid REFRESH_INTERVAL_SECONDS="$rawInterval" (must be positive int)',
        tag: 'Env',
      );
    }
  }
  runApp(const MyApp());
}

/// Widget gốc của app, quản lý trạng thái khởi động và điều hướng màn hình đầu tiên
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
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
      return;
    }
    // Kiểm tra access token
    String? accessToken = prefs.getString(kAccessTokenKey);
    if (accessToken == null) {
      setState(() {
        _home = const WelcomeScreen();
        _loading = false;
      });
      return;
    }
    // Nếu có token, thử gọi API lấy profile
    try {
      var user = await ApiService.getProfile(accessToken);
      // Nếu token hết hạn hoặc lỗi, thử refresh token
      if (user == null) {
        final refreshToken = await _secureStorage.read(key: kRefreshTokenKey);
        if (refreshToken != null) {
          final outcome = await TokenManager.instance.forceRefresh(
            refreshToken: refreshToken,
          );
          if (outcome.ok && outcome.pair != null) {
            accessToken = outcome.pair!.accessToken;
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
        } else {
          AppLogger.info(
            'Vào MainScreen (cold start), start scheduler',
            tag: 'App',
          );
          setState(() {
            _home = const MainScreen();
            _loading = false;
          });
          // Start fixed-interval scheduler with an immediate refresh attempt.
          // Fire and forget; errors already logged inside scheduler.
          RefreshScheduler.instance.start(immediate: true);
        }
      } else {
        // Token hết hạn hoặc refresh thất bại, xóa token và về màn hình welcome
        await prefs.remove(kAccessTokenKey);
        await _secureStorage.delete(key: kRefreshTokenKey);
        setState(() {
          _home = const WelcomeScreen();
          _loading = false;
        });
      }
    } catch (e) {
      await prefs.remove(kAccessTokenKey);
      await _secureStorage.delete(key: kRefreshTokenKey);
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
