import 'package:flutter/material.dart';
import '../../repositories/exercises_repository.dart';
import '../../models/exercise_model.dart';
import '../../widgets/search_box.dart';
import '../../widgets/app_button.dart';
import '../../widgets/exercise_simple_card.dart';

class ExerciseListScreen extends StatefulWidget {
  final String muscleGroupId;
  final String muscleGroupName;
  const ExerciseListScreen({
    super.key,
    required this.muscleGroupId,
    required this.muscleGroupName,
  });

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final _repo = ExercisesRepository();
  bool _loading = true;
  String? _error;
  List<ExerciseModel> _items = [];
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
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
      final data = widget.muscleGroupId == '_ALL_'
          ? await _repo.getAll()
          : await _repo.getByMuscleGroup(widget.muscleGroupId);
      setState(() {
        _items = data;
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

  List<ExerciseModel> get _filtered {
    if (_query.isEmpty) return _items;
    final q = _query.toLowerCase();
    return _items.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.muscleGroupName,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          SearchBox(
            controller: _searchCtrl,
            hint: 'Tìm bài tập...',
            variant: SearchBoxVariant.elevated,
            onChanged: (v) => setState(() => _query = v.trim()),
            onClear: () => setState(() => _query = ''),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          ),
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
                          child: Text(
                            'Lỗi: $_error',
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            width: 160,
                            child: AppButton.primary(
                              label: 'Thử lại',
                              onPressed: _fetch,
                              size: AppButtonSize.small,
                            ),
                          ),
                        ),
                      ],
                    )
                  : filtered.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Center(
                            child: Text(
                              'Không có bài tập',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final ex = filtered[i];
                        return ExerciseSimpleCard(
                          exercise: ex,
                          onTap: () {}, // placeholder: could navigate detail
                          compact: false,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
