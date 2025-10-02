import 'package:flutter/material.dart';
import '../../../core/extensions/color_extensions.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_snack_bar.dart';
import '../../../widgets/exercise_hero_header.dart';
import '../../../repositories/workout_day_exercises_repository.dart';
import '../../../models/exercise_model.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../widgets/expandable_body_text.dart';

class ConfigureExerciseScreen extends StatefulWidget {
  final String workoutPlanId;
  final String workoutDayId;
  final int dayNumber;
  final ExerciseModel exercise;
  const ConfigureExerciseScreen({
    super.key,
    required this.workoutPlanId,
    required this.workoutDayId,
    required this.dayNumber,
    required this.exercise,
  });

  @override
  State<ConfigureExerciseScreen> createState() =>
      _ConfigureExerciseScreenState();
}

class _ConfigureExerciseScreenState extends State<ConfigureExerciseScreen> {
  final _repo = WorkoutDayExercisesRepository();
  final _setsCtl = TextEditingController();
  final _repsCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  final _restCtl = TextEditingController();
  // Notes removed per request; keep placeholder if future reinstatement needed.
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setsCtl.text = (widget.exercise.defaultSets ?? 3).toString();
    _repsCtl.text = (widget.exercise.defaultReps ?? 10).toString();
    _weightCtl.text = (widget.exercise.defaultWeight ?? 0).toString();
    _restCtl.text = (widget.exercise.restTime ?? 60).toString();
  }

  @override
  void dispose() {
    _setsCtl.dispose();
    _repsCtl.dispose();
    _weightCtl.dispose();
    _restCtl.dispose();
    // _notesCtl disposed (removed UI)
    super.dispose();
  }

  int _parseInt(
    TextEditingController c, {
    int fallback = 0,
    int min = 0,
    int max = 999,
  }) {
    final v = int.tryParse(c.text.trim());
    final clamped = (v ?? fallback).clamp(min, max);
    return clamped;
  }

  double _parseDouble(
    TextEditingController c, {
    double fallback = 0,
    double min = 0,
    double max = 9999,
  }) {
    final v = double.tryParse(c.text.trim());
    final clamped = (v ?? fallback).clamp(min, max);
    return clamped.toDouble();
  }

  // Training volume logic removed from UI; computation dropped.

  bool get _isValid =>
      _parseInt(_setsCtl, fallback: 0) > 0 &&
      _parseInt(_repsCtl, fallback: 0) > 0 &&
      _parseInt(_restCtl, fallback: 0) >= 0 &&
      (_lockWeight
          ? _parseDouble(_weightCtl, fallback: 0, min: 0) >= 0
          : _parseDouble(_weightCtl, fallback: 0, min: 0) > 0);

  bool get _lockWeight => (widget.exercise.defaultWeight ?? 0) == 0;

  bool _isInvalidForField(TextEditingController ctl, String label) {
    if (label == 'Sets' || label == 'Reps') {
      return _parseInt(ctl, fallback: 0) <= 0;
    }
    if (label == 'Rest') {
      return _parseInt(ctl, fallback: -1) < 0;
    }
    if (label == 'Weight') {
      final w = _parseDouble(ctl, fallback: -1);
      // For weighted exercises (defaultWeight > 0), weight must stay > 0
      return _lockWeight ? w < 0 : w <= 0;
    }
    return false;
  }

  Future<void> _submit() async {
    if (!_isValid) {
      setState(() => _error = 'Vui lòng nhập dữ liệu hợp lệ');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await _repo.create(
        workoutPlanId: widget.workoutPlanId,
        workoutDayId: widget.workoutDayId,
        exerciseId: widget.exercise.id,
        dayNumber: widget.dayNumber,
        targetSets: _parseInt(_setsCtl, fallback: 3, min: 1),
        targetReps: _parseInt(_repsCtl, fallback: 10, min: 1),
        targetWeight: _parseDouble(_weightCtl, fallback: 0, min: 0),
        restTimeSec: _parseInt(_restCtl, fallback: 60, min: 0),
        // Notes intentionally null (notes feature removed)
        notes: null,
      );
      if (!mounted) return;
      if (created != null) {
        // Return created to previous route; upstream screens now forward this result until reaching WorkoutExerciseDetailScreen.
        Navigator.pop(context, created);
      } else {
        setState(() => _error = 'Không tạo được bài tập');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _bump(
    TextEditingController ctl,
    int delta, {
    int min = 0,
    int max = 999,
  }) {
    final v = int.tryParse(ctl.text) ?? min;
    final nv = (v + delta).clamp(min, max);
    ctl.text = nv.toString();
    setState(() {});
  }

  Widget _numberSegment({
    required String label,
    required TextEditingController ctl,
    String? suffix,
    int min = 0,
    int max = 999,
    bool disabled = false,
  }) {
    final invalid = _isInvalidForField(ctl, label);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: invalid
                ? Colors.redAccent.withOpacityRatio(0.6)
                : Colors.grey[800]!,
            width: invalid ? 1.2 : 1,
          ),
          boxShadow: [
            if (!invalid)
              BoxShadow(
                color: Colors.black.withOpacityRatio(0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: invalid ? Colors.redAccent : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _circleBtn(
                  Icons.remove,
                  disabled
                      ? () => AppSnackBar.showInfo(
                          context,
                          'Bài tập dạng bodyweight - không chỉnh được tạ',
                        )
                      : () => _bump(ctl, -1, min: min, max: max),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctl,
                    onChanged: (_) => setState(() {}),
                    readOnly: disabled,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  Text(
                    suffix,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                ],
                _circleBtn(
                  Icons.add,
                  disabled
                      ? () => AppSnackBar.showInfo(
                          context,
                          'Bài tập dạng bodyweight - không chỉnh được tạ',
                        )
                      : () => _bump(ctl, 1, min: min, max: max),
                ),
              ],
            ),
            if (invalid)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Giá trị không hợp lệ',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return _AnimatedIconButton(icon: icon, onTap: onTap);
  }

  // Summary card removed; replaced by hero header + sections.

  // Removed old _heroHeader; using shared ExerciseHeroHeader

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0B0C0E),
          // AppBar removed for immersive header
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseHeroHeader(
                  title: widget.exercise.name,
                  muscleGroups: widget.exercise.muscleGroupNames,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacityRatio(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withOpacityRatio(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const _SectionTitle(text: 'Giới thiệu'),
                      const SizedBox(height: 10),
                      ExpandableBodyText(
                        text:
                            widget.exercise.description?.trim().isNotEmpty ==
                                true
                            ? widget.exercise.description!
                                  .trim()
                                  .normalizedMultiline()
                            : 'Chưa có giới thiệu cho bài tập này.',
                        trimLines: 6,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(text: 'Hướng dẫn'),
                      const SizedBox(height: 10),
                      ExpandableBodyText(
                        text:
                            widget.exercise.instruction?.trim().isNotEmpty ==
                                true
                            ? widget.exercise.instruction!
                                  .trim()
                                  .normalizedMultiline()
                            : (widget.exercise.description?.trim().isNotEmpty ==
                                      true
                                  ? widget.exercise.description!
                                        .trim()
                                        .normalizedMultiline()
                                  : 'Chưa có hướng dẫn chi tiết.'),
                        trimLines: 6,
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(text: 'Thiết lập mục tiêu'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _numberSegment(
                            label: 'Sets',
                            ctl: _setsCtl,
                            min: 1,
                            max: 50,
                          ),
                          const SizedBox(width: 12),
                          _numberSegment(
                            label: 'Reps',
                            ctl: _repsCtl,
                            min: 1,
                            max: 200,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _numberSegment(
                            label: 'Weight',
                            ctl: _weightCtl,
                            min: _lockWeight ? 0 : 1,
                            max: 2000,
                            suffix: 'kg',
                            disabled: _lockWeight,
                          ),
                          const SizedBox(width: 12),
                          _numberSegment(
                            label: 'Rest',
                            ctl: _restCtl,
                            min: 0,
                            max: 1000,
                            suffix: 's',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomSheet: _BottomBar(
            enabled: _isValid && !_submitting,
            submitting: _submitting,
            onSubmit: _submit,
          ),
        ),
        if (_submitting)
          Container(
            color: Colors.black.withOpacityRatio(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

// _VolumeCard removed.

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final bool submitting;
  final VoidCallback onSubmit;
  const _BottomBar({
    required this.enabled,
    required this.submitting,
    required this.onSubmit,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0C0E).withOpacityRatio(0.96),
        border: const Border(
          top: BorderSide(color: Colors.white10, width: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityRatio(0.7),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: AppButton.gradient(
        label: submitting ? 'Đang lưu...' : 'Thêm bài tập',
        loading: submitting,
        leadingIcon: submitting ? null : Icons.add_rounded,
        onPressed: enabled && !submitting ? onSubmit : null,
        size: AppButtonSize.large,
      ),
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AnimatedIconButton({required this.icon, required this.onTap});
  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.18,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() async {
    try {
      // Optional: light haptic feedback
      // ignore: deprecated_member_use
      // HapticFeedback.selectionClick(); (need import services if enabled)
    } catch (_) {}
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _press,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _scale.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: Colors.white, size: 18),
            ),
          );
        },
      ),
    );
  }
}
