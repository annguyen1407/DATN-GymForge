import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/animations/animated_appear.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Tập luyện cá nhân',
      'desc':
          'Xây dựng chế độ tập phù hợp với bản thân mà không cần sự hỗ trợ bên ngoài',
      'image': 'assets/images/onboarding_1.png',
    },
    {
      'title': 'Theo dõi tiến độ',
      'desc': 'Dễ dàng theo dõi tiến độ tập luyện của bạn thân',
      'image': 'assets/images/onboarding_2.png',
    },
    {
      'title': 'Đạt mục tiêu',
      'desc': 'Lập kế hoạch tập luyện và hoàn thành mục tiêu của bạn',
      'image': 'assets/images/onboarding_3.png',
    },
  ];

  Future<void> _finishOnboarding(BuildContext context) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    navigator.pushReplacementNamed('/welcome');
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Onboarding hiện là static assets + local state nên chưa cần skeleton.
    // Nếu sau này có gọi API (ví dụ remote config) có thể thêm shimmer placeholder
    // hoặc AnimatedOpacity cho phần text / image.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (int index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: onboardingData.length,
              itemBuilder: (context, index) {
                final data = onboardingData[index];
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(data['image']!, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 24),
                    child: GestureDetector(
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('seenOnboarding', true);
                        if (!mounted) return;
                        navigator.pushReplacementNamed('/welcome');
                      },
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 480),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                              child: child,
                            ),
                          ),
                          child: Column(
                            key: ValueKey(_currentPage),
                            children: [
                              AnimatedAppear(
                                child: Text(
                                  onboardingData[_currentPage]['title']!,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedAppear(
                                delay: const Duration(milliseconds: 80),
                                dy: 20,
                                child: Text(
                                  onboardingData[_currentPage]['desc']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 32),
                              AnimatedAppear(
                                delay: const Duration(milliseconds: 160),
                                dy: 14,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    onboardingData.length,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: _currentPage == index ? 12 : 10,
                                      height: _currentPage == index ? 12 : 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentPage == index
                                            ? const Color(0xFF8854FF)
                                            : Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              AnimatedAppear(
                                delay: const Duration(milliseconds: 240),
                                dy: 20,
                                child: AppButton.primary(
                                  label:
                                      _currentPage < onboardingData.length - 1
                                      ? 'Tiếp theo'
                                      : 'Đăng ký ngay',
                                  size: AppButtonSize.large,
                                  onPressed: _nextPage,
                                  leadingIcon:
                                      _currentPage < onboardingData.length - 1
                                      ? Icons.arrow_forward
                                      : Icons.person_add_alt_1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
