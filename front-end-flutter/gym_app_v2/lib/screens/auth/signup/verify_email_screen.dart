import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import 'verify_success_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  int _seconds = 600; // 10 phút
  late final String _maskedEmail;
  String _timerText = '';
  bool _isResending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _maskedEmail = _maskEmail(widget.email);
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _seconds = 600;
    _timerText = _formatTime(_seconds);
    Future.doWhile(() async {
      if (_seconds == 0) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _seconds--;
        _timerText = _formatTime(_seconds);
      });
      return _seconds > 0;
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts[0].length <= 2) return email;
    final visible = parts[0].substring(0, 2);
    final masked = '*' * (parts[0].length - 2);
    return '$visible$masked@${parts[1]}';
  }

  void _onOtpChanged(int idx, String value) async {
    if (value.length == 1 && idx < 5) {
      _focusNodes[idx + 1].requestFocus();
    }
    if (value.isEmpty && idx > 0) {
      _focusNodes[idx - 1].requestFocus();
    }
    // Tự động submit khi nhập đủ 6 số
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6 && otp.runes.every((r) => r >= 48 && r <= 57)) {
      await _onSubmit();
    }
  }

  Future<void> _onSubmit() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) return;
    setState(() => _error = null);
    final success = await ApiService.verifyEmailOTP(
      email: widget.email,
      otp: otp,
    );
    if (success) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VerifySuccessScreen()),
      );
    } else {
      setState(() {
        _error = 'Mã xác thực không đúng hoặc đã hết hạn!';
      });
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _onResend() async {
    setState(() => _isResending = true);
    final ok = await ApiService.resendVerificationOTP(email: widget.email);
    setState(() => _isResending = false);
    if (ok) {
      _startTimer();
      setState(() => _error = null);
    } else {
      setState(() => _error = 'Gửi lại mã thất bại, thử lại sau!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF232323), Color(0xFF181818)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        width: 2,
                        color: Colors.purpleAccent.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nhập mã xác nhận',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mã gửi tới',
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _maskedEmail,
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            text: 'Mã này sẽ có hiệu lực trong ',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 15,
                            ),
                            children: [
                              TextSpan(
                                text: _formatTime(_seconds),
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (idx) {
                            return Container(
                              width: 40,
                              height: 48,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF232232),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _focusNodes[idx].hasFocus
                                      ? Colors.purpleAccent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _controllers[idx],
                                  focusNode: _focusNodes[idx],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (v) => _onOtpChanged(idx, v),
                                  onSubmitted: (_) => _onSubmit(),
                                ),
                              ),
                            );
                          }),
                        ),
                        // Hiển thị lỗi nếu có
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Không nhận được mã?',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: (_seconds == 0 && !_isResending)
                                  ? _onResend
                                  : null,
                              child: Text(
                                _isResending ? 'Đang gửi lại...' : 'Gửi lại mã',
                                style: TextStyle(
                                  color: (_seconds == 0 && !_isResending)
                                      ? Colors.purpleAccent
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  decoration: (_seconds == 0 && !_isResending)
                                      ? TextDecoration.underline
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
