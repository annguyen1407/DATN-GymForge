import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/workout_plans_repository.dart';

class CreateWorkoutPlanScreen extends StatefulWidget {
  final String userId;
  const CreateWorkoutPlanScreen({super.key, required this.userId});

  @override
  State<CreateWorkoutPlanScreen> createState() =>
      _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(); // new
  String? _selectedPlanType; // new
  bool _submitting = false;
  final _repo = WorkoutPlansRepository();
  String? _attachedImagePath; // future enhancement: pick image

  static const List<String> _planTypes = [
    'STRENGTH',
    'CARDIO',
    'FLEXIBILITY',
    'COMBINED',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final int? days = _daysCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_daysCtrl.text.trim());
      final plan = await _repo.createPlan(
        userId: widget.userId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        planType: _selectedPlanType,
        days: days,
      );
      if (!mounted) return;
      if (plan != null) {
        Navigator.pop(context, plan);
      } else {
        _showSnack('Tạo kế hoạch thất bại');
      }
    } catch (e) {
      _showSnack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(String hint, {Widget? prefixIcon}) =>
        InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: prefixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tạo kế hoạch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'savePlanFab',
        backgroundColor: const Color(0xFFA26FFD),
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check, color: Colors.white),
        label: Text(_submitting ? 'Đang lưu...' : 'Lưu kế hoạch'),
      ),
      body: Stack(
        children: [
          // Gradient header nền
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F1F1F), Color(0xFF0D0D0D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Nội dung cuộn
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 110, 20, 120),
              children: [
                _SectionLabel(title: 'Thông tin chính'),
                const SizedBox(height: 12),
                _GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration(
                          'Tên kế hoạch',
                          prefixIcon: const Icon(
                            Icons.dataset,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPlanType,
                        dropdownColor: const Color(0xFF1E1E1E),
                        items: _planTypes
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        decoration: inputDecoration(
                          'Loại kế hoạch',
                          prefixIcon: const Icon(
                            Icons.category,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        onChanged: (v) => setState(() => _selectedPlanType = v),
                        validator: (v) => v == null ? 'Chọn loại' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _daysCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration(
                          'Số ngày (tuỳ chọn)',
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = int.tryParse(v.trim());
                          if (n == null) return 'Không hợp lệ';
                          if (n <= 0) return 'Phải > 0';
                          if (n > 365) return 'Quá dài (<=365)';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _SectionLabel(title: 'Mô tả chi tiết'),
                const SizedBox(height: 12),
                _GlassCard(
                  child: _DescriptionCard(
                    controller: _descCtrl,
                    onAttach: () async {
                      _showSnack('Chức năng đính kèm đang phát triển');
                    },
                    attached: _attachedImagePath != null,
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Nhấn Lưu kế hoạch để hoàn tất',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.5),
                      fontSize: 12,
                      letterSpacing: .3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAttach;
  final bool attached;
  const _DescriptionCard({
    required this.controller,
    required this.onAttach,
    required this.attached,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: 6,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nhập mô tả chi tiết (tuỳ chọn)',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, size: 18, color: Colors.white30),
                const SizedBox(width: 6),
                Text(
                  attached ? '1 tệp đã chọn' : 'Đính kèm ảnh (sắp có)',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: onAttach,
              icon: const Icon(
                Icons.attachment,
                color: Colors.white54,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Nhãn section
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(.72),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

// Card hiệu ứng nhẹ (glass / elevated dark)
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: child,
    );
  }
}
