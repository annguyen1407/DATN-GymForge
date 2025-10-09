// ...existing code...
import 'package:flutter/material.dart';
import '../../../core/logging/app_logger.dart';
import '../../../services/api_service.dart';
import 'verify_email_screen.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/animations/animated_appear.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _validatePassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~_\-\^%\.,:;\?\(\)\[\]\{\}<>]).{8,}$',
    );
    return regex.hasMatch(password);
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  String _selectedRole = 'GYMER'; // Default to GYMER

  Future<void> _signup() async {
    setState(() {
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();

    // Validate fields
    if (name.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập đầy đủ thông tin.';
      });
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\u0000?$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _error = 'Email không đúng định dạng.';
      });
      return;
    }
    if (username.length < 4 || username.contains(' ')) {
      setState(() {
        _error = 'Tên đăng nhập phải từ 4 ký tự, không chứa khoảng trắng.';
      });
      return;
    }
    if (!_validatePassword(password)) {
      setState(() {
        _error =
            'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });
    final body = {
      "email": email,
      "password": password,
      "username": username,
      "name": name,
      "role": _selectedRole,
    };
    final result = await ApiService.signup(body);
    if (!mounted) return; // context safety
    AppLogger.info('Signup response:');
    AppLogger.debug('$result', tag: 'Signup');
    if (result != null && result['status'] == 201) {
      setState(() {
        _loading = false;
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VerifyEmailScreen(email: email),
        ),
      );
      return;
    } else if (result != null && result['status'] == 409) {
      if (!mounted) return;
      setState(() {
        _error = 'Email hoặc tên đăng nhập đã tồn tại!';
        _loading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _error = 'Đăng ký thất bại!';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: AnimatedAppear(
                    dy: 14,
                    child: Text(
                      'Đăng ký và bắt đầu tập luyện',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedAppear(
                  delay: const Duration(milliseconds: 60),
                  dy: 18,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 100),
                          dy: 12,
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.white54,
                              ),
                              hintText: 'Họ và tên',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.grey[850],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 140),
                          dy: 12,
                          child: TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.white54,
                              ),
                              hintText: 'Tên đăng nhập',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.grey[850],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Email
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 160),
                          dy: 12,
                          child: TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Colors.white54,
                              ),
                              hintText: 'Địa chỉ Email',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.grey[850],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 200),
                          dy: 12,
                          child: TextField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.white54,
                              ),
                              hintText: 'Mật khẩu',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.grey[850],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Role picker moved here
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 240),
                          dy: 12,
                          child: _RolePickerField(
                            value: _selectedRole,
                            onChanged: (v) => setState(() => _selectedRole = v),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        const AnimatedAppear(
                          delay: Duration(milliseconds: 260),
                          dy: 10,
                          child: Text(
                            'By signing up you agree to our Term of use and privacy notice',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _error == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  key: const ValueKey('error'),
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                        ),
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 300),
                          dy: 10,
                          child: AppButton.primary(
                            label: 'Đăng ký ngay',
                            size: AppButtonSize.large,
                            loading: _loading,
                            onPressed: _loading ? null : _signup,
                            leadingIcon: _loading
                                ? null
                                : Icons.person_add_alt_1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 340),
                          dy: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Đã đăng ký? ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/signin',
                                ),
                                child: const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    color: Color(0xFF8854FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _RolePickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RolePickerField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final roleLabel = value == 'COACH' ? 'Huấn luyện viên' : 'Gymer';
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.person, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                roleLabel,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const Icon(Icons.expand_more, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              _RoleOption(
                label: 'Gymer',
                role: 'GYMER',
                selected: value == 'GYMER',
                onTap: () {
                  onChanged('GYMER');
                  Navigator.pop(ctx);
                },
              ),
              _RoleOption(
                label: 'Huấn luyện viên',
                role: 'COACH',
                selected: value == 'COACH',
                onTap: () {
                  onChanged('COACH');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String role;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleOption({
    required this.role,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8854FF).withOpacity(.15) : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.person,
              color: selected ? const Color(0xFF8854FF) : Colors.white54,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF8854FF), size: 20)
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: Colors.white30,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
