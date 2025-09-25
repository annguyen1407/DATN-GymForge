import 'package:flutter/material.dart';
import '../../repositories/exercises_repository.dart';
import '../../models/exercise_model.dart';
import '../../widgets/search_box.dart';
import '../../widgets/app_button.dart';
import '../../widgets/exercise_simple_card.dart';
import '../../widgets/pagination_bar.dart';
import 'exercise_info_screen.dart';

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
  // Dynamic pagination sizing
  int _pageSize = 25; // recalculated to fit viewport
  int _page = 1; // 1-based
  bool _pageSizeInitialized = false;

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

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 999999);
  List<ExerciseModel> get _pageItems {
    if (_filtered.isEmpty) return const [];
    if (_page > _totalPages) _page = _totalPages;
    final start = (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  void _resetPage() => _page = 1;
  void _changePage(int p) {
    if (p != _page) setState(() => _page = p);
  }

  void _recalculatePageSize(BuildContext context) {
    if (_pageSizeInitialized) return;
    const estimatedCardHeight = 118.0; // non-compact card a bit taller
    final media = MediaQuery.of(context);
    final appBarHeight = kToolbarHeight + media.padding.top;
    const searchArea = 76.0; // SearchBox area
    const paginationArea = 70.0;
    final available =
        media.size.height - appBarHeight - searchArea - paginationArea;
    if (available > 220) {
      final perPage = (available / estimatedCardHeight).floor().clamp(3, 25);
      if (perPage != _pageSize) {
        setState(() {
          _pageSize = perPage;
          _page = 1;
          _pageSizeInitialized = true;
        });
      } else {
        _pageSizeInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _recalculatePageSize(context);
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
            onChanged: (v) => setState(() {
              _query = v.trim();
              _resetPage();
            }),
            onClear: () => setState(() {
              _query = '';
              _resetPage();
            }),
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
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            itemCount: _pageItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final ex = _pageItems[i];
                              return ExerciseSimpleCard(
                                exercise: ex,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExerciseInfoScreen(
                                        exerciseId: ex.id,
                                      ),
                                    ),
                                  );
                                },
                                compact: false,
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
          ),
        ],
      ),
    );
  }
}
