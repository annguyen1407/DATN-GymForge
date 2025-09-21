import 'package:flutter/material.dart';
import '../../../repositories/muscle_groups_repository.dart';
import '../../../models/muscle_group_model.dart';
import 'select_exercise_screen.dart';
import '../../../widgets/exercise_group_card.dart';

class SelectMuscleGroupScreen extends StatefulWidget {
  final String workoutPlanId;
  final String workoutDayId;
  final int dayNumber;
  final List<String>
  excludedExerciseIds; // danh sách exerciseId đã có trong ngày
  const SelectMuscleGroupScreen({
    super.key,
    required this.workoutPlanId,
    required this.workoutDayId,
    required this.dayNumber,
    this.excludedExerciseIds = const [],
  });

  @override
  State<SelectMuscleGroupScreen> createState() =>
      _SelectMuscleGroupScreenState();
}

class _SelectMuscleGroupScreenState extends State<SelectMuscleGroupScreen> {
  final _repo = MuscleGroupsRepository();
  late Future<List<MuscleGroupModel>> _future;
  final _searchCtl = TextEditingController();
  List<MuscleGroupModel> _all = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MuscleGroupModel>> _load() async {
    final data = await _repo.getMuscleGroups();
    _all = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Chọn nhóm cơ',
          style: TextStyle(
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
                hintText: 'Tìm nhóm cơ...',
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
                setState(() => _query = v.trim().toLowerCase());
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MuscleGroupModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Build filtered list with synthetic 'All' card at top
                final filtered = _all
                    .where(
                      (m) =>
                          _query.isEmpty ||
                          m.name.toLowerCase().contains(_query),
                    )
                    .toList();

                // Insert synthetic all item (client-side)
                final totalCount = filtered.fold<int>(
                  0,
                  (sum, m) => sum + m.exercisesCount,
                );
                final items = [
                  MuscleGroupModel(
                    id: '_ALL_',
                    name: 'Tất cả',
                    exercisesCount: totalCount,
                  ),
                  ...filtered,
                ];

                if (filtered.isEmpty && _query.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'Không tìm thấy nhóm cơ',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.9, // match exercise_screen look
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final mg = items[i];
                    return ExerciseGroupCard(
                      name: mg.name,
                      count: mg.exercisesCount,
                      highlight: mg.id == '_ALL_',
                      onTap: () async {
                        final created = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectExerciseScreen(
                              muscleGroup: mg,
                              workoutPlanId: widget.workoutPlanId,
                              workoutDayId: widget.workoutDayId,
                              dayNumber: widget.dayNumber,
                              excludedExerciseIds: widget.excludedExerciseIds,
                            ),
                          ),
                        );
                        if (created != null) {
                          if (mounted) Navigator.pop(context, created);
                        }
                      },
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
