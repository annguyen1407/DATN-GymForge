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
      _all = all
          .where((e) => e.muscleGroupNames.contains(widget.muscleGroup.name))
          .toList();
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
        title: Text('Nhóm: ${widget.muscleGroup.name}'),
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
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey[800], height: 1),
                    itemBuilder: (context, i) {
                      final ex = _filtered[i];
                      return ListTile(
                        title: Text(
                          ex.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: ex.muscleGroupNames.isNotEmpty
                            ? Text(
                                ex.muscleGroupNames.join(', '),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white54,
                        ),
                        onTap: () {
                          Navigator.push(
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
