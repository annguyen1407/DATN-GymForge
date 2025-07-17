import 'package:flutter/material.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import 'app_routes_old.dart';

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.onboarding: (_) => const OnboardingScreen(),
  AppRoutes.welcome: (_) => const WelcomeScreen(),
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.register: (_) => const RegisterScreen(),
};
