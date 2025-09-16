import 'package:flutter/material.dart';
import '../../repositories/exercises_repository.dart';
import '../../models/exercise_model.dart';
import '../../widgets/search_box.dart';

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
      if (mounted)
        setState(() {
          _loading = false;
        });
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
                        TextButton(
                          onPressed: _fetch,
                          child: const Text('Thử lại'),
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
                        return _ExerciseCard(ex: ex);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseModel ex;
  const _ExerciseCard({required this.ex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
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
                  _Chip(text: '${ex.defaultSets}x${ex.defaultReps}')
                else if (ex.defaultSets != null)
                  _Chip(text: '${ex.defaultSets} sets'),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: -4,
              children: [
                if (ex.restTime != null)
                  _SmallIconText(
                    icon: Icons.timer_outlined,
                    text: '${ex.restTime}s',
                  ),
                if (ex.met != null)
                  _SmallIconText(
                    icon: Icons.local_fire_department_outlined,
                    text: '${ex.met} MET',
                  ),
                if (ex.defaultWeight != null)
                  _SmallIconText(
                    icon: Icons.fitness_center_outlined,
                    text: '${ex.defaultWeight}kg',
                  ),
              ],
            ),
            if (ex.description != null && ex.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _stripPrefix(ex.description!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
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
          ],
        ),
      ),
    );
  }

  String _stripPrefix(String s) {
    // Remove known "Mô tả:" prefix if present
    return s.replaceFirst(RegExp(r'^Mô tả:\s*'), '');
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
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

class _SmallIconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SmallIconText({required this.icon, required this.text});
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
