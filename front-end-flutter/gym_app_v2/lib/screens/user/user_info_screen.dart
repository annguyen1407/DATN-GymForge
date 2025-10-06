import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../core/logging/app_logger.dart';

/// UserInfoScreen: hiển thị & chỉnh sửa các thông tin mở rộng của user.
/// Trường: biography (multiline), weight (double), height (int), sex (select), dateOfBirth (date)
class UserInfoScreen extends StatefulWidget {
  final UserModel user;
  const UserInfoScreen({super.key, required this.user});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late TextEditingController _bioCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _addressCtrl;
  String? _sex; // MALE/FEMALE
  DateTime? _dob;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.user.biography ?? '');
    _weightCtrl = TextEditingController(
      text: widget.user.weight != null ? widget.user.weight!.toString() : '',
    );
    _heightCtrl = TextEditingController(
      text: widget.user.height != null ? widget.user.height!.toString() : '',
    );
    _addressCtrl = TextEditingController(text: widget.user.address ?? '');
    _sex = widget.user.sex;
    if (widget.user.dateOfBirth != null &&
        widget.user.dateOfBirth!.isNotEmpty) {
      try {
        _dob = DateTime.parse(widget.user.dateOfBirth!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Huỷ',
      confirmText: 'Lưu',
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'biography': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'weight': double.tryParse(_weightCtrl.text.trim()),
        'height': int.tryParse(_heightCtrl.text.trim()),
        'sex': _sex,
        'address': _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        'dateOfBirth': _dob != null
            ? _dob!.toIso8601String().split('T')[0]
            : null,
      };
      AppLogger.debug('PATCH user info: $body', tag: 'UserInfo');
      final ok = await UserService.updateProfile(context, body);
      if (!mounted) return;
      if (ok) {
        AppSnackBar.showSuccess(context, 'Cập nhật thành công');
        Navigator.pop(context, true);
      } else {
        AppSnackBar.showError(context, 'Cập nhật thất bại');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Thông tin người dùng'),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final current = FocusScope.of(context);
          if (!current.hasPrimaryFocus && current.focusedChild != null) {
            current.unfocus();
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Tiểu sử'),
                _CardContainer(
                  child: TextField(
                    controller: _bioCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Chia sẻ đôi chút về bạn...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionLabel('Địa chỉ'),
                _CardContainer(
                  child: TextField(
                    controller: _addressCtrl,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'VD: 123 Nguyễn Trãi, Hà Nội',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionLabel('Thể chất'),
                _CardContainer(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _FieldLabelWrapper(
                              label: 'Cân nặng (kg)',
                              child: TextField(
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Ví dụ 70',
                                  hintStyle: TextStyle(color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _FieldLabelWrapper(
                              label: 'Chiều cao (cm)',
                              child: TextField(
                                controller: _heightCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Ví dụ 170',
                                  hintStyle: TextStyle(color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _FieldLabelWrapper(
                              label: 'Giới tính',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sex,
                                  dropdownColor: const Color(0xFF1F1A29),
                                  iconEnabledColor: Colors.white70,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'MALE',
                                      child: Text('Nam'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'FEMALE',
                                      child: Text('Nữ'),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() => _sex = v),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _FieldLabelWrapper(
                              label: 'Ngày sinh',
                              child: GestureDetector(
                                onTap: _pickDob,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _dob != null
                                            ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                                            : 'DD/MM/YYYY',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
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
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppButton.gradient(
                  label: _saving ? 'Đang lưu...' : 'Lưu thay đổi',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1A29),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabelWrapper extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldLabelWrapper({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: .3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2336),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: child,
        ),
      ],
    );
  }
}
