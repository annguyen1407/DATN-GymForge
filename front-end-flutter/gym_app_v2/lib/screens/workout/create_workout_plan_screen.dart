import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
import 'package:flutter/services.dart';
import '../../repositories/workout_plans_repository.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_button.dart';

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
  // Days input removed: API will receive days = 0 by default
  String? _selectedPlanType; // new
  bool _submitting = false;
  final _repo = WorkoutPlansRepository();
  String? _attachedImagePath; // future enhancement: pick image

  static const Map<String, String> _planTypeVN = {
    'STRENGTH': 'Sức mạnh',
    'FLEXIBILITY': 'Dẻo dai',
    'CARDIO': 'Sức bền',
    'COMBINED': 'Kết hợp',
  };

  static const Map<String, Color> _typeColors = {
    'STRENGTH': Colors.pinkAccent,
    'FLEXIBILITY': Color(0xFF26A69A),
    'CARDIO': Color(0xFFFF9800),
    'COMBINED': Color(0xFF9C27B0),
  };

  String _typeLabel(String? k) =>
      k == null ? 'Chọn loại kế hoạch' : (_planTypeVN[k] ?? k);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Validation thủ công trước call API
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnackSafe(
        ScaffoldMessenger.of(context),
        'Tên kế hoạch không được trống',
      );
      return;
    }
    if (_selectedPlanType == null) {
      _showSnackSafe(
        ScaffoldMessenger.of(context),
        'Vui lòng chọn loại kế hoạch',
      );
      return;
    }
    // days optional validation
    if (!_formKey.currentState!.validate()) {
      return; // still respect field validators
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final plan = await _repo.createPlan(
        userId: widget.userId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        planType: _selectedPlanType,
        days: 0,
      );
      if (!mounted) return; // widget still active?
      if (plan != null) {
        navigator.pop(plan);
      } else {
        _showSnackSafe(messenger, 'Tạo kế hoạch thất bại');
      }
    } catch (e) {
      if (mounted) _showSnackSafe(messenger, 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackSafe(ScaffoldMessengerState messenger, String message) {
    if (!mounted) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.grey.shade900.withOpacityRatio(.95),
      ),
    );
  }

  void _showSnack(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('lỗi') || lower.contains('thất bại')) {
      AppSnackBar.showError(context, msg);
    } else {
      AppSnackBar.showInfo(context, msg);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // _canSubmit computed via getters; rebuild triggers reflect changes.
    // Compact input decoration (reduced vertical padding & consistent styling)
    InputDecoration inputDecoration(String hint, {Widget? prefixIcon}) =>
        InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
          top: 8,
        ),
        child: AppButton.primary(
          label: _submitting ? 'Đang lưu...' : 'Lưu kế hoạch',
          leadingIcon: _submitting ? null : Icons.check_rounded,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
          size: AppButtonSize.large,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B1B1B), Color(0xFF0E0E0E)],
                ),
              ),
            ),
          ),
          // Center card similar to edit dialog but scrollable content inside
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1F1F1F), Color(0xFF141414)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacityRatio(0.07),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacityRatio(0.65),
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                            ),
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacityRatio(0.1),
                              blurRadius: 36,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        // Reduced padding for a denser card layout
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: const [
                                Expanded(
                                  child: Text(
                                    'Tạo kế hoạch mới',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: .3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameCtrl,
                              enabled: !_submitting,
                              decoration: inputDecoration(
                                'Tên kế hoạch',
                                prefixIcon: const Icon(
                                  Icons.dataset,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Không được để trống'
                                  : null,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loại kế hoạch',
                              style: TextStyle(
                                color: Colors.white.withOpacityRatio(.9),
                                fontSize: 13,
                                letterSpacing: .2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _PlanTypeCompactSelector(
                              selectedType: _selectedPlanType,
                              typeColors: _typeColors,
                              labelBuilder: _typeLabel,
                              enabled: !_submitting,
                              onPick: (t) =>
                                  setState(() => _selectedPlanType = t),
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 18),
                            Text(
                              'Mô tả chi tiết',
                              style: TextStyle(
                                color: Colors.white.withOpacityRatio(.72),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _GlassCard(
                              child: _DescriptionCard(
                                controller: _descCtrl,
                                onAttach: () async {
                                  _showSnack(
                                    'Chức năng đính kèm đang phát triển',
                                  );
                                },
                                attached: _attachedImagePath != null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                'Nhấn Lưu kế hoạch để hoàn tất',
                                style: TextStyle(
                                  color: Colors.white.withOpacityRatio(.45),
                                  fontSize: 12,
                                  letterSpacing: .3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact selector widgets (copied & adapted from edit dialog implementation)
class _PlanTypeCompactSelector extends StatefulWidget {
  final String? selectedType;
  final Map<String, Color> typeColors;
  final String Function(String?) labelBuilder;
  final bool enabled;
  final ValueChanged<String> onPick;
  const _PlanTypeCompactSelector({
    required this.selectedType,
    required this.typeColors,
    required this.labelBuilder,
    required this.enabled,
    required this.onPick,
  });

  @override
  State<_PlanTypeCompactSelector> createState() =>
      _PlanTypeCompactSelectorState();
}

class _PlanTypeCompactSelectorState extends State<_PlanTypeCompactSelector> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool get _open => _entry != null;
  static const _types = ['FLEXIBILITY', 'STRENGTH', 'CARDIO', 'COMBINED'];

  void _toggle() {
    if (!widget.enabled) return;
    if (_open) {
      _close();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(0, 0);
    _entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacityRatio(.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacityRatio(.6),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final t in _types)
                        _TypeMenuItem(
                          active: widget.selectedType == t,
                          label: widget.labelBuilder(t),
                          color: widget.typeColors[t] ?? Colors.pinkAccent,
                          onTap: () {
                            widget.onPick(t);
                            _close();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_entry != null) {
      // Avoid scheduling a rebuild after dispose
      _entry?.remove();
      _entry = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = widget.selectedType != null;
    final Color? activeColor = hasSelection
        ? (widget.typeColors[widget.selectedType] ?? Colors.pinkAccent)
        : null; // no accent when unselected
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasSelection
                  ? activeColor!.withOpacityRatio(.9)
                  : Colors.white.withOpacityRatio(.14),
              width: 1.05,
            ),
            gradient: hasSelection
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF242424),
                      activeColor!.withOpacityRatio(.20),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF242424), Color(0xFF242424)],
                  ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.category_rounded,
                color: hasSelection
                    ? activeColor!.withOpacityRatio(.95)
                    : Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.labelBuilder(widget.selectedType),
                  style: TextStyle(
                    color: hasSelection ? Colors.white : Colors.white60,
                    fontSize: 14.2,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedRotation(
                duration: const Duration(milliseconds: 220),
                turns: _open ? .5 : 0,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasSelection
                      ? activeColor!.withOpacityRatio(.95)
                      : Colors.white38,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeMenuItem extends StatelessWidget {
  final bool active;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TypeMenuItem({
    required this.active,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacityRatio(.15) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_off,
              color: active ? color : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : Colors.white.withOpacityRatio(.8),
                  fontSize: 13.6,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (active) Icon(Icons.check, color: color, size: 18),
          ],
        ),
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
// (Removed unused _SectionLabel widget from original list-based layout.)

// Card hiệu ứng nhẹ (glass / elevated dark)
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacityRatio(.85),
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
