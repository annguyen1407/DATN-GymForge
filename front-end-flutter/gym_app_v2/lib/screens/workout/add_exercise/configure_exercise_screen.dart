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
  final _notesCtl = TextEditingController();
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
    _notesCtl.dispose();
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

  double get _trainingVolume =>
      _parseInt(_setsCtl, fallback: 1, min: 1) *
      _parseInt(_repsCtl, fallback: 1, min: 1) *
      _parseDouble(_weightCtl).toDouble();

  bool get _isValid =>
      _parseInt(_setsCtl, fallback: 0) > 0 &&
      _parseInt(_repsCtl, fallback: 0) > 0 &&
      _parseInt(_restCtl, fallback: 0) >= 0 &&
      _parseDouble(_weightCtl, fallback: 0, min: 0) >= 0;

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
        notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
      );
      if (!mounted) return;
      if (created != null) {
        // Pop until first route before this screen (we pushed 3 screens total earlier) - just return created once.
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    final volume = _trainingVolume;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Cấu hình bài tập'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryCard(),
                const SizedBox(height: 20),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        color: Colors.orangeAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Training volume: ${volume.toStringAsFixed(0)} (sets * reps * weight)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesCtl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (optional)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValid
                          ? const Color(0xFFFF6B6B)
                          : Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _submitting ? 'Đang thêm...' : 'Thêm vào ngày tập',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
