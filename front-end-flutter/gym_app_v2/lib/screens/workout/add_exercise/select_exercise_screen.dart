import 'package:flutter/material.dart';
import '../../../models/muscle_group_model.dart';
import '../../../repositories/exercises_repository.dart';
import '../../../models/exercise_model.dart';
import 'configure_exercise_screen.dart';
import '../../../widgets/exercise_simple_card.dart';
import '../../../widgets/pagination_bar.dart';

class SelectExerciseScreen extends StatefulWidget {
  final MuscleGroupModel muscleGroup;
  final String workoutPlanId;
  final String workoutDayId;
  final int dayNumber;
  final List<String> excludedExerciseIds; // exerciseId đã tồn tại trong ngày
  const SelectExerciseScreen({
    super.key,
    required this.muscleGroup,
    required this.workoutPlanId,
    required this.workoutDayId,
    required this.dayNumber,
    this.excludedExerciseIds = const [],
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

  // Pagination state (dynamic page size to fit viewport)
  int _pageSize = 25; // will be recalculated after first layout
  int _page = 1; // 1-based
  bool _initializedPageSize = false;

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 999999);

  List<ExerciseModel> get _pageItems {
    if (_filtered.isEmpty) return const [];
    if (_page > _totalPages) _page = _totalPages; // safety adjust
    final start = (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _repo.getAll();
      if (widget.muscleGroup.id == '_ALL_') {
        _all = all;
      } else {
        _all = all
            .where((e) => e.muscleGroupNames.contains(widget.muscleGroup.name))
            .toList();
      }
      if (widget.excludedExerciseIds.isNotEmpty) {
        _all = _all
            .where((e) => !widget.excludedExerciseIds.contains(e.id))
            .toList();
      }
      _applyFilter(resetPage: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter({bool resetPage = false}) {
    _filtered = _all
        .where((e) => _query.isEmpty || e.name.toLowerCase().contains(_query))
        .toList();
    if (resetPage) {
      _page = 1;
    } else if (_page > _totalPages)
      // ignore: curly_braces_in_flow_control_structures
      _page = _totalPages;
    setState(() {});
  }

  void _onSearchChanged(String v) {
    _query = v.trim().toLowerCase();
    _applyFilter(resetPage: true);
  }

  void _changePage(int p) {
    if (p == _page) return;
    setState(() => _page = p);
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _recalculatePageSize(BuildContext context) {
    if (_initializedPageSize) return;
    // Estimate card height (compact mode) + spacing.
    // We can approximate by creating a TextPainter? Simpler: use fixed heuristic.
    // Components: card vertical padding (~12*2 + internal content ~56) ≈ 90 + separator 12.
    const estimatedCardWithSpacing =
        102.0; // heuristic for compact card + separator
    final media = MediaQuery.of(context);
    final appBarHeight = kToolbarHeight + media.padding.top;
    // Height used by search box area (~16 padding + textfield 56 + bottom margin 0) ≈ 88
    const searchArea = 88.0;
    // Height used by pagination bar (approx 70 including padding)
    const paginationArea = 70.0;
    final available =
        media.size.height - appBarHeight - searchArea - paginationArea;
    if (available > 200) {
      final perPage = (available / estimatedCardWithSpacing).floor().clamp(
        3,
        40,
      );
      if (perPage != _pageSize) {
        setState(() {
          _pageSize = perPage;
          _page = 1; // reset to first page after dynamic change
          _initializedPageSize = true;
        });
      } else {
        _initializedPageSize = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _recalculatePageSize(context);
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
              onChanged: _onSearchChanged,
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
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: _pageItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final ex = _pageItems[i];
                            return ExerciseSimpleCard(
                              exercise: ex,
                              compact: true,
                              showDescription: false,
                              onTap: () async {
                                final navigator = Navigator.of(context);
                                final created = await navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => ConfigureExerciseScreen(
                                      workoutPlanId: widget.workoutPlanId,
                                      workoutDayId: widget.workoutDayId,
                                      dayNumber: widget.dayNumber,
                                      exercise: ex,
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                if (created != null && mounted) {
                                  navigator.pop(created);
                                }
                              },
                            );
                          },
                        ),
                      ),
                      PaginationBar(
                        currentPage: _page,
                        totalItems: _filtered.length,
                        pageSize: _pageSize,
                        onPageChanged: _changePage,
                        groupSize: 7,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// _Tag widget removed (muscle group tags hidden per request).
