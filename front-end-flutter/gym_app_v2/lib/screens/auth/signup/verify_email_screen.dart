import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import 'verify_success_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  late final String _maskedEmail;
  bool _isResending = false;
  String? _error;
  int _resendCooldown = 0;
  String _cooldownText = '';
  int _resendCount = 0;

  @override
  void initState() {
    super.initState();
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

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final maskedName = name.length <= 2
        ? '${name[0]}*'
        : name.substring(0, 2) + '*' * (name.length - 2);
    return '$maskedName@${parts[1]}';
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 5; // đổi thành 5s để debug nhanh
      _cooldownText = _formatTime(_resendCooldown);
    });
    Future.doWhile(() async {
      if (_resendCooldown == 0) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCooldown--;
        _cooldownText = _formatTime(_resendCooldown);
      });
      return _resendCooldown > 0;
    }).then((_) {
      if (mounted) {
        setState(() {
          _resendCooldown = 0;
          _cooldownText = '';
          // _resendCount = 0; // Không reset nữa, mọi lần gửi tiếp theo đều phải chờ 5s
        });
      }
    });
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

  void _onOtpChanged(int idx, String value) async {
    if (value.length == 1 && idx < 5) {
      _focusNodes[idx + 1].requestFocus();
    }
    if (value.isEmpty && idx > 0) {
      _focusNodes[idx - 1].requestFocus();
    }
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6 && otp.runes.every((r) => r >= 48 && r <= 57)) {
      await _onSubmit();
    }
  }

  void _onResend() async {
    if (_resendCooldown > 0) return;
    if (_resendCount < 3) {
      setState(() => _isResending = true);
      final ok = await ApiService.resendVerificationOTP(email: widget.email);
      setState(() => _isResending = false);
      if (ok) {
        setState(() {
          _error = null;
          _resendCount++;
        });
        if (_resendCount == 3) {
          _startResendCooldown();
        }
      } else {
        setState(() => _error = 'Gửi lại mã thất bại, thử lại sau!');
      }
    } else {
      // Đã bị tính spam, mỗi lần bấm đều phải chờ cooldown và đều call API
      setState(() => _isResending = true);
      final ok = await ApiService.resendVerificationOTP(email: widget.email);
      setState(() => _isResending = false);
      if (ok) {
        setState(() {
          _error = null;
        });
        _startResendCooldown();
      } else {
        setState(() => _error = 'Gửi lại mã thất bại, thử lại sau!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        const Text(
                          'Mã có hiệu lực trong 10 phút',
                          style: TextStyle(color: Colors.white54, fontSize: 15),
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
                              onTap: (_isResending || _resendCooldown > 0)
                                  ? null
                                  : _onResend,
                              child: Text(
                                _isResending ? 'Đang gửi lại...' : 'Gửi lại mã',
                                style: TextStyle(
                                  color: (_isResending || _resendCooldown > 0)
                                      ? Colors.grey
                                      : Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  decoration:
                                      (_isResending || _resendCooldown > 0)
                                      ? null
                                      : TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_resendCooldown > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Bạn có thể gửi lại mã sau $_cooldownText',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
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
