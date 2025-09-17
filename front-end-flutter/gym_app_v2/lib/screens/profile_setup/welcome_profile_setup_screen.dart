import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';

class WelcomeProfileSetupScreen extends StatelessWidget {
  final String userName;
  const WelcomeProfileSetupScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/onboarding_1.png', // Đặt tên file ảnh nền đúng với assets của bạn
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar placeholder
                const SizedBox(height: 32),
                // Chào mừng
                Text(
                  'Chào mừng, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Trước khi bắt đầu tập luyện, hãy để chúng tôi tìm hiểu về thông tin cá nhân của bạn để giúp quá trình tập luyện tốt hơn',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AppButton.gradient(
                    label: 'Điền thông tin cá nhân của tôi',
                    size: AppButtonSize.large,
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/profile-setup');
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AppButton.text(
                  label: 'Tạm thời bỏ qua',
                  onPressed: () {
                    // TODO: Logic skip profile setup
                  },
                  fullWidth: false,
                  size: AppButtonSize.small,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
