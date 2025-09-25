import 'package:flutter/material.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/animations/animated_appear.dart';

class VerifySuccessScreen extends StatelessWidget {
  const VerifySuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnimatedAppear(dy: 30, child: _IconSuccessStack()),
                const SizedBox(height: 36),
                const AnimatedAppear(
                  delay: Duration(milliseconds: 120),
                  child: Text(
                    'Xác thực thành công',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                const AnimatedAppear(
                  delay: Duration(milliseconds: 220),
                  dy: 16,
                  child: Text(
                    'You have successfully verified your email. You can now log in to your account and start using the app.',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                AnimatedAppear(
                  delay: const Duration(milliseconds: 360),
                  dy: 18,
                  child: SizedBox(
                    width: 220,
                    child: AppButton.primary(
                      label: 'Login Now',
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/signin'),
                      size: AppButtonSize.medium,
                      fullWidth: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconSuccessStack extends StatefulWidget {
  const _IconSuccessStack();

  @override
  State<_IconSuccessStack> createState() => _IconSuccessStackState();
}

class _IconSuccessStackState extends State<_IconSuccessStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scalePhone;
  late final Animation<double> _scaleCheck;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scalePhone = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _scaleCheck = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.elasticOut),
    );
    // start next frame to allow first build settle
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Stack(
        alignment: Alignment.topRight,
        children: [
          Transform.scale(
            scale: _scalePhone.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A65),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.phone_iphone, color: Colors.white, size: 80),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Transform.scale(
              scale: _scaleCheck.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8854FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
