import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_screen.dart';
//import 'screens/auth/login_screen.dart';
import 'utils/launch_helper.dart';
import 'screens/auth/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _loading = true;
  bool _firstLaunch = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  void _checkFirstLaunch() async {
    final isFirst = await LaunchHelper.isFirstLaunch();
    setState(() {
      _firstLaunch = isFirst;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _firstLaunch ? const OnboardingScreen() : const WelcomeScreen();
  }
}
