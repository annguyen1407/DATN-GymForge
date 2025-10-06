import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../../widgets/exercise_group_card.dart';
import '../../widgets/search_box.dart';
import '../../repositories/muscle_groups_repository.dart';
import '../../models/muscle_group_model.dart';
import 'exercise_list_screen.dart';

/// ExerciseScreen: Gọi API /muscle-groups và hiển thị danh sách nhóm cơ.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final _repo = MuscleGroupsRepository();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<MuscleGroupModel> _groups = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getMuscleGroups();
      data.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _groups = data;
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _query = '';
  List<MuscleGroupModel> get _filtered {
    if (_query.isEmpty) return _groups;
    final q = _query.toLowerCase();
    return _groups.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  void _applyFilter() {
    setState(() {
      _query = _searchCtrl.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    // Tính tổng 'Tất cả'
    final total = _groups.fold<int>(0, (p, e) => p + e.exercisesCount);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Bài tập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SearchBox(
              controller: _searchCtrl,
              hint: 'Tìm nhóm cơ...',
              variant: SearchBoxVariant.elevated,
              onChanged: (_) => _applyFilter(),
              onClear: () => _applyFilter(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetch,
                color: Colors.pinkAccent,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.pinkAccent,
                        ),
                      )
                    : _error != null
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'Lỗi tải dữ liệu:\n$_error',
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Center(
                            child: SizedBox(
                              width: 140,
                              child: AppButton.primary(
                                label: 'Thử lại',
                                onPressed: _fetch,
                                size: AppButtonSize.small,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          itemCount: filtered.length + 1, // +1 cho "Tất cả"
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.8,
                              ),
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return ExerciseGroupCard(
                                name: 'Tất cả',
                                count: total,
                                highlight: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ExerciseListScreen(
                                        muscleGroupId: '_ALL_',
                                        muscleGroupName: 'Tất cả bài tập',
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            final g = filtered[i - 1];
                            return ExerciseGroupCard(
                              name: g.name,
                              count: g.exercisesCount,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ExerciseListScreen(
                                      muscleGroupId: g.id,
                                      muscleGroupName: g.name,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
