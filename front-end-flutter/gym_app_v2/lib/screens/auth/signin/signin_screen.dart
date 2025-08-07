import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../profile_setup/welcome_profile_setup_screen.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() {
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\u0000?$');
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập đầy đủ thông tin.';
      });
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _error = 'Email không đúng định dạng.';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _error = 'Mật khẩu phải từ 6 ký tự.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });
    final data = await ApiService.login(email, password);
    if (data != null &&
        data['status'] != null &&
        (data['status'] == 200 || data['status'] == 201) &&
        data['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công!')));
      // Kiểm tra dateOfBirth
      final user = data['user'];
      if (user != null && user['dateOfBirth'] == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                WelcomeProfileSetupScreen(userName: user['fullName'] ?? ''),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/main', (route) => false);
      }
    } else if (data != null && data['status'] == 401) {
      final msg = (data['message'] ?? '').toString().toLowerCase();
      if (msg.contains('verify your email')) {
        setState(() {
          _error = 'Vui lòng xác nhận email trước khi đăng nhập!';
        });
      } else {
        setState(() {
          _error = 'Email hoặc mật khẩu không đúng!';
        });
      }
    } else {
      setState(() {
        _error = 'Đăng nhập thất bại!';
      });
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Chào mừng bạn đã trở lại !',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.white54,
                            ),
                            hintText: 'Email',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
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
                        // ...existing code...
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 24),
                        // ...existing code...
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8854FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ...existing code...
                        // ...existing code...
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Không có tài khoản? ',
                              style: TextStyle(color: Colors.white70),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                context,
                                '/signup',
                              ),
                              child: const Text(
                                'Đăng ký',
                                style: TextStyle(
                                  color: Color(0xFF8854FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Thêm chức năng quên tài khoản
                            },
                            child: const Text(
                              'Quên tài khoản ?',
                              style: TextStyle(
                                color: Color(0xFF8854FF),
                                fontWeight: FontWeight.bold,
                              ),
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
        ),
      ),
    );
  }
}
