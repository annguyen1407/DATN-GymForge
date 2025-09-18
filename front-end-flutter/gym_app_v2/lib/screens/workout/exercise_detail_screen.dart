import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../../repositories/exercises_repository.dart';
import '../../models/exercise_model.dart';
import '../../repositories/workout_day_exercises_repository.dart';
import '../../widgets/exercise_actions_menu.dart';
import '../../widgets/destructive_confirm_sheet.dart';
import '../../widgets/app_snack_bar.dart';

/// ExerciseDetailScreen: giao diện thống nhất với ConfigureExerciseScreen (hero + sections)
class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;
  final String? workoutPlanId; // cần cho PATCH
  final String? workoutDayId; // cần cho PATCH
  final String? workoutDayExerciseId; // id record để PATCH
  final int initialSets;
  final int initialReps;
  final double initialWeight;
  final int initialRest; // seconds
  final String? backgroundImage; // optional local asset path
  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    this.workoutPlanId,
    this.workoutDayId,
    this.workoutDayExerciseId,
    required this.initialSets,
    required this.initialReps,
    required this.initialWeight,
    required this.initialRest,
    this.backgroundImage,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final _repo = ExercisesRepository();
  final _wdeRepo = WorkoutDayExercisesRepository();
  final _setsCtl = TextEditingController();
  final _repsCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  final _restCtl = TextEditingController();
  bool _saving = false;
  bool _deleting = false;
  String? _error;
  bool _loading = true;
  String? _loadError;
  ExerciseModel? _exercise;

  @override
  void initState() {
    super.initState();
    _setsCtl.text = widget.initialSets.toString();
    _repsCtl.text = widget.initialReps.toString();
    _weightCtl.text = widget.initialWeight % 1 == 0
        ? widget.initialWeight.toInt().toString()
        : widget.initialWeight.toStringAsFixed(1);
    _restCtl.text = widget.initialRest.toString();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final ex = await _repo.getById(widget.exerciseId);
      if (!mounted) return;
      if (ex == null) {
        setState(() => _loadError = 'Không tải được bài tập');
      } else {
        setState(() => _exercise = ex);
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _setsCtl.dispose();
    _repsCtl.dispose();
    _weightCtl.dispose();
    _restCtl.dispose();
    super.dispose();
  }

  int _parseInt(
    TextEditingController c, {
    int fallback = 0,
    int min = 0,
    int max = 9999,
  }) {
    final v = int.tryParse(c.text.trim());
    return (v ?? fallback).clamp(min, max);
  }

  double _parseDouble(
    TextEditingController c, {
    double fallback = 0,
    double min = 0,
    double max = 9999,
  }) {
    final v = double.tryParse(c.text.trim());
    final value = (v ?? fallback).clamp(min, max);
    return value.toDouble();
  }

  bool get _isValid =>
      _parseInt(_setsCtl, fallback: 0, min: 1) > 0 &&
      _parseInt(_repsCtl, fallback: 0, min: 1) > 0 &&
      _parseInt(_restCtl, fallback: 0, min: 0) >= 0 &&
      _parseDouble(_weightCtl, fallback: 0, min: 0) >= 0;

  bool _isInvalidForField(TextEditingController ctl, String label) {
    if (label == 'Sets' || label == 'Reps') {
      return _parseInt(ctl, fallback: 0, min: 1) <= 0;
    }
    if (label == 'Rest') {
      return _parseInt(ctl, fallback: -1) < 0;
    }
    if (label == 'Weight') {
      return _parseDouble(ctl, fallback: -1) < 0;
    }
    return false;
  }

  void _bump(
    TextEditingController ctl,
    int delta, {
    int min = 0,
    int max = 9999,
  }) {
    final v = int.tryParse(ctl.text) ?? min;
    final nv = (v + delta).clamp(min, max);
    ctl.text = nv.toString();
    setState(() {});
  }

  Future<void> _save() async {
    if (!_isValid) {
      setState(() => _error = 'Giá trị không hợp lệ');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      WorkoutDayExerciseDto? updated;
      final sets = _parseInt(_setsCtl, fallback: 3, min: 1);
      final reps = _parseInt(_repsCtl, fallback: 10, min: 1);
      final weight = _parseDouble(_weightCtl, fallback: 0, min: 0);
      final rest = _parseInt(_restCtl, fallback: 60, min: 0);
      final canPatch =
          widget.workoutPlanId != null &&
          widget.workoutDayId != null &&
          widget.workoutDayExerciseId != null &&
          widget.workoutPlanId!.isNotEmpty &&
          widget.workoutDayId!.isNotEmpty &&
          widget.workoutDayExerciseId!.isNotEmpty;
      if (canPatch) {
        final repo = WorkoutDayExercisesRepository();
        updated = await repo.update(
          id: widget.workoutDayExerciseId!,
          workoutPlanId: widget.workoutPlanId!,
          workoutDayId: widget.workoutDayId!,
          exerciseId: widget.exerciseId,
          targetSets: sets,
          targetReps: reps,
          targetWeight: weight,
          restTimeSec: rest,
          notes: null,
        );
      } else {
        // fallback local delay nếu thiếu context
        await Future.delayed(const Duration(milliseconds: 400));
      }
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        canPatch
            ? 'Đã cập nhật bài tập'
            : 'Đã lưu cục bộ (thiếu context PATCH)',
      );
      Navigator.pop(context, {
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'rest': rest,
        'exerciseId': widget.exerciseId,
        if (updated != null) 'updatedDto': updated,
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.workoutDayExerciseId == null ||
        widget.workoutDayExerciseId!.isEmpty) {
      AppSnackBar.showWarning(context, 'Không có ID record để xoá');
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DestructiveConfirmSheet(
        title: 'Xoá bài tập',
        message:
            'Bạn chắc chắn muốn xoá bài tập này khỏi ngày tập?\n\n"${_exercise?.name ?? ''}"',
        confirmLabel: 'Xoá',
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok != true) return;
    setState(() => _deleting = true);
    try {
      final success = await _wdeRepo.delete(widget.workoutDayExerciseId!);
      if (!mounted) return;
      if (success) {
        AppSnackBar.showSuccess(context, 'Đã xoá bài tập');
        Navigator.pop(context, {
          'deleted': true,
          'workoutDayExerciseId': widget.workoutDayExerciseId,
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Xoá thất bại: $e');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Widget _numberSegment({
    required String label,
    required TextEditingController ctl,
    String? suffix,
    int min = 0,
    int max = 9999,
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
                ? Colors.redAccent.withOpacity(0.6)
                : Colors.grey[800]!,
            width: invalid ? 1.2 : 1,
          ),
          boxShadow: [
            if (!invalid)
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
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
                  () => _bump(ctl, -1, min: min, max: max),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctl,
                    onChanged: (_) => setState(() {}),
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
                _circleBtn(Icons.add, () => _bump(ctl, 1, min: min, max: max)),
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

  Widget _circleBtn(IconData icon, VoidCallback onTap) =>
      _AnimatedIconButton(icon: icon, onTap: onTap);
  Widget _heroHeader(BuildContext context) {
    final mg = _exercise?.muscleGroupNames ?? const [];
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child:
                (widget.backgroundImage != null &&
                    widget.backgroundImage!.isNotEmpty)
                ? Image.asset(
                    widget.backgroundImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _gradientFallback(),
                  )
                : _gradientFallback(),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  AppSnackBar.showInfo(context, 'Video demo chưa khả dụng');
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.92),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: MediaQuery.of(context).padding.top + 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Menu hành động (chỉ có xoá)
          Positioned(
            right: 4,
            top: MediaQuery.of(context).padding.top + 4,
            child: ExerciseActionsMenu(
              isDeleting: _deleting,
              onAction: (a) async {
                if (a == ExerciseAction.delete) {
                  await _confirmDelete();
                }
              },
            ),
          ),
          Positioned(
            bottom: 18,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _exercise?.name ?? 'Đang tải...',
                    key: ValueKey(_exercise?.id ?? 'loading'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (mg.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < mg.take(4).length; i++)
                        _MuscleTag(text: mg[i], highlight: i == 0),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2F33), Color(0xFF181A1D)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instruction = _exercise?.instruction?.trim();
    final description = _exercise?.description?.trim();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0E),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: Colors.pinkAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroHeader(context),
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
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Giá trị không hợp lệ',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_loadError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _loadError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            AppButton.text(
                              label: 'Thử lại',
                              onPressed: _fetch,
                              size: AppButtonSize.small,
                              fullWidth: false,
                            ),
                          ],
                        ),
                      )
                    else if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                    const _SectionTitle(text: 'Giới thiệu'),
                    const SizedBox(height: 10),
                    Text(
                      (instruction != null && instruction.isNotEmpty)
                          ? instruction
                          : 'Chưa có giới thiệu cho bài tập này.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(text: 'Hướng dẫn'),
                    const SizedBox(height: 10),
                    Text(
                      (description != null && description.isNotEmpty)
                          ? description
                          : (instruction?.isNotEmpty == true
                                ? instruction!
                                : 'Chưa có hướng dẫn chi tiết.'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
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
                          max: 300,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _numberSegment(
                          label: 'Weight',
                          ctl: _weightCtl,
                          min: 0,
                          max: 2000,
                          suffix: 'kg',
                        ),
                        const SizedBox(width: 12),
                        _numberSegment(
                          label: 'Rest',
                          ctl: _restCtl,
                          min: 0,
                          max: 2000,
                          suffix: 's',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _BottomBar(
        enabled: _isValid && !_saving,
        submitting: _saving,
        onSubmit: _save,
        label: 'Lưu thay đổi',
      ),
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

  void _press() {
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

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final bool submitting;
  final VoidCallback onSubmit;
  final String label;
  const _BottomBar({
    required this.enabled,
    required this.submitting,
    required this.onSubmit,
    required this.label,
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
        color: const Color(0xFF0B0C0E).withOpacity(0.96),
        border: const Border(
          top: BorderSide(color: Colors.white10, width: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: AppButton.gradient(
        label: submitting ? 'Đang lưu...' : label,
        loading: submitting,
        leadingIcon: submitting ? null : Icons.save_rounded,
        onPressed: enabled && !submitting ? onSubmit : null,
        size: AppButtonSize.large,
      ),
    );
  }
}

// (ExerciseSpec model removed – legacy parsing no longer needed after refactor.)

class _MuscleTag extends StatelessWidget {
  final String text;
  final bool highlight;
  const _MuscleTag({required this.text, required this.highlight});
  @override
  Widget build(BuildContext context) {
    if (highlight) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
