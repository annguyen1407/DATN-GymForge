import 'package:flutter/material.dart';
import '../../../models/muscle_group_model.dart';
import '../../../repositories/exercises_repository.dart';
import '../../../models/exercise_model.dart';
import 'configure_exercise_screen.dart';

class SelectExerciseScreen extends StatefulWidget {
  final MuscleGroupModel muscleGroup;
  final String workoutPlanId;
  final String workoutDayId;
  final int dayNumber;
  const SelectExerciseScreen({
    super.key,
    required this.muscleGroup,
    required this.workoutPlanId,
    required this.workoutDayId,
    required this.dayNumber,
  });

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> {
  final _repo = ExercisesRepository();
  List<ExerciseModel> _all = [];
  List<ExerciseModel> _filtered = [];
  bool _loading = true;
  String _query = '';
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Ideally backend has endpoint by muscle group id; if not, filter client side.
      final all = await _repo.getAll();
      if (widget.muscleGroup.id == '_ALL_') {
        // Hiển thị tất cả bài tập
        _all = all;
      } else {
        _all = all
            .where((e) => e.muscleGroupNames.contains(widget.muscleGroup.name))
            .toList();
      }
      _applyFilter();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    _filtered = _all
        .where((e) => _query.isEmpty || e.name.toLowerCase().contains(_query))
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Nhóm: ${widget.muscleGroup.name}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm bài tập...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                _query = v.trim().toLowerCase();
                _applyFilter();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Không có bài tập',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final ex = _filtered[i];
                      return _ExerciseSelectCard(
                        ex: ex,
                        onTap: () async {
                          final created = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfigureExerciseScreen(
                                workoutPlanId: widget.workoutPlanId,
                                workoutDayId: widget.workoutDayId,
                                dayNumber: widget.dayNumber,
                                exercise: ex,
                              ),
                            ),
                          );
                          if (created != null) {
                            // Pop this screen and return created upward so the detail screen can refresh.
                            if (mounted) Navigator.pop(context, created);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSelectCard extends StatelessWidget {
  final ExerciseModel ex;
  final VoidCallback onTap;
  const _ExerciseSelectCard({required this.ex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (ex.defaultSets != null && ex.defaultReps != null)
                  _SpecChip(text: '${ex.defaultSets}x${ex.defaultReps}')
                else if (ex.defaultSets != null)
                  _SpecChip(text: '${ex.defaultSets} sets'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: -4,
              children: [
                if (ex.restTime != null)
                  _IconText(
                    icon: Icons.timer_outlined,
                    text: '${ex.restTime}s',
                  ),
                if (ex.met != null)
                  _IconText(
                    icon: Icons.local_fire_department_outlined,
                    text: '${ex.met} MET',
                  ),
                if (ex.defaultWeight != null)
                  _IconText(
                    icon: Icons.fitness_center_outlined,
                    text: '${ex.defaultWeight}kg',
                  ),
              ],
            ),
            if (ex.muscleGroupNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: ex.muscleGroupNames
                    .take(3)
                    .map((n) => _Tag(text: n))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String text;
  const _SpecChip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.pinkAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconText({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }
}
