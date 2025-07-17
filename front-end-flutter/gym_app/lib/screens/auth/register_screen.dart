import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedSex = 'MALE';
  String _selectedExp = 'Beginner';
  bool _isLoading = false;

  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "username": _usernameController.text.trim(),
      "name": _nameController.text.trim(),
      "phoneNumber": _phoneController.text.trim(),
      "role": "GYMER",
      "dateOfBirth": _dobController.text.trim(),
      "sex": _selectedSex,
      "address": _addressController.text.trim(),
      "weight": double.tryParse(_weightController.text.trim()) ?? 0,
      "height": int.tryParse(_heightController.text.trim()) ?? 0,
      "goal": _goalController.text.trim(),
      "expType": _selectedExp,
      "biography": _bioController.text.trim(),
    };

    setState(() => _isLoading = true);
    final success = await _authService.register(body);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Register successful')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Register failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh (YYYY-MM-DD)',
                ),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
              ),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Chiều cao (cm)'),
              ),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Mục tiêu tập luyện',
                ),
              ),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Giới thiệu bản thân',
                ),
              ),

              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                items: ['MALE', 'FEMALE']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedSex = val!),
                decoration: const InputDecoration(labelText: 'Giới tính'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedExp,
                items: ['Beginner', 'Intermediate', 'Advanced']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedExp = val!),
                decoration: const InputDecoration(labelText: 'Kinh nghiệm tập'),
              ),

              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitRegister,
                      child: const Text('Đăng ký'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
