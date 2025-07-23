import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/signup/signup_screen.dart';
import 'screens/auth/signin/signin_screen.dart';
import 'screens/profile_setup/profile_setup_screen.dart';
import 'screens/profile_setup/welcome_profile_setup_screen.dart';

void main() {
  runApp(const MyApp());
}

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
    final accessToken = prefs.getString('access_token');
    if (accessToken == null) {
      setState(() {
        _home = const WelcomeScreen();
        _loading = false;
      });
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('http://localhost:3000/auth/profile'),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $accessToken'},
      );
      if (res.statusCode == 200) {
        final user = json.decode(res.body);
        if (user['dateOfBirth'] == null) {
          setState(() {
            _home = WelcomeProfileSetupScreen(userName: user['name'] ?? '');
            _loading = false;
          });
        } else {
          // TODO: Chuyển sang màn hình chính sau khi đã đủ thông tin
          setState(() {
            _home = const WelcomeScreen();
            _loading = false;
          });
        }
      } else {
        await prefs.remove('access_token');
        setState(() {
          _home = const WelcomeScreen();
          _loading = false;
        });
      }
    } catch (e) {
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
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _home,
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
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
