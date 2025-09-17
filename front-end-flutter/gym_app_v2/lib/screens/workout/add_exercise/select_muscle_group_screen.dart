import 'package:flutter/material.dart';
import '../../../repositories/muscle_groups_repository.dart';
import '../../../models/muscle_group_model.dart';
import 'select_exercise_screen.dart';

class SelectMuscleGroupScreen extends StatefulWidget {
  final String workoutPlanId;
  final String workoutDayId;
  final int dayNumber;
  const SelectMuscleGroupScreen({
    super.key,
    required this.workoutPlanId,
    required this.workoutDayId,
    required this.dayNumber,
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
                final items =
                    [
                      MuscleGroupModel(
                        id: '_ALL_',
                        name: 'Tất cả',
                        exercisesCount: 0,
                      ),
                    ] +
                    filtered;

                if (filtered.isEmpty && _query.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'Không tìm thấy nhóm cơ',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final mg = items[i];
                    return _MuscleGroupCard(
                      mg: mg,
                      isAll: mg.id == '_ALL_',
                      onTap: () async {
                        final created = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectExerciseScreen(
                              muscleGroup: mg,
                              workoutPlanId: widget.workoutPlanId,
                              workoutDayId: widget.workoutDayId,
                              dayNumber: widget.dayNumber,
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

class _MuscleGroupCard extends StatelessWidget {
  final MuscleGroupModel mg;
  final bool isAll;
  final VoidCallback onTap;
  const _MuscleGroupCard({
    required this.mg,
    required this.isAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[800]!, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isAll
                    ? Colors.pinkAccent.withOpacity(0.15)
                    : Colors.deepPurple.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAll ? Icons.all_inclusive : Icons.fitness_center,
                color: isAll ? Colors.pinkAccent : Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mg.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isAll ? 'Tất cả bài tập' : '${mg.exercisesCount} bài tập',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
