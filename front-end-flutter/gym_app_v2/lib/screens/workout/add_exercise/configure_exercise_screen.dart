import 'package:flutter/material.dart';
import '../../../repositories/workout_day_exercises_repository.dart';
import '../../../models/exercise_model.dart';

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
      _parseDouble(_weightCtl, fallback: 0, min: 0) >= 0;

  bool _isInvalidForField(TextEditingController ctl, String label) {
    if (label == 'Sets' || label == 'Reps') {
      return _parseInt(ctl, fallback: 0) <= 0;
    }
    if (label == 'Rest') {
      return _parseInt(ctl, fallback: -1) < 0;
    }
    if (label == 'Weight') {
      return _parseDouble(ctl, fallback: -1) < 0; // negative not allowed
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

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _summaryCard() {
    final mg = widget.exercise.muscleGroupNames;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E2EFF), Color(0xFF8A4DFF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (mg.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: mg
                  .take(5)
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        e,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat('MET', widget.exercise.met?.toStringAsFixed(1) ?? '--'),
              _miniStat('Rest', '${widget.exercise.restTime ?? 60}s'),
              _miniStat('Sets', (widget.exercise.defaultSets ?? 3).toString()),
              _miniStat('Reps', (widget.exercise.defaultReps ?? 10).toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Volume calculation retained internally but UI hidden.
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0B0C0E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B0C0E),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Cấu hình bài tập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryCard(),
                    const SizedBox(height: 24),
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
                    const _SectionTitle(text: 'Thông số chính'),
                    const SizedBox(height: 12),
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
                          min: 0,
                          max: 2000,
                          suffix: 'kg',
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
                    // Volume card removed.
                  ],
                ),
              );
            },
          ),
          bottomSheet: _BottomBar(
            enabled: _isValid && !_submitting,
            submitting: _submitting,
            onSubmit: _submit,
          ),
        ),
        if (_submitting)
          Container(
            color: Colors.black.withOpacity(0.5),
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
    final disabled = !enabled;
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
      child: GestureDetector(
        onTap: disabled ? null : onSubmit,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: disabled ? 0.55 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
            decoration: BoxDecoration(
              gradient: disabled
                  ? LinearGradient(
                      colors: [Colors.grey[800]!, Colors.grey[700]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.32),
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!submitting) ...[
                  const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: submitting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Đang lưu...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Thêm bài tập',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
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
