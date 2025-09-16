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
        title: const Text('Chọn nhóm cơ'),
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
                final list = _all
                    .where(
                      (m) =>
                          _query.isEmpty ||
                          m.name.toLowerCase().contains(_query),
                    )
                    .toList();
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có nhóm cơ',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey[800], height: 1),
                  itemBuilder: (context, i) {
                    final mg = list[i];
                    return ListTile(
                      title: Text(
                        mg.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        Navigator.push(
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
