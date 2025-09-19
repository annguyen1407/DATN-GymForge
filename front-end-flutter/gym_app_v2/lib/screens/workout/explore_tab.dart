// Removed imports for template cards & sections (exclusive/quick) after cleanup.
import 'package:flutter/material.dart';
import '../../repositories/workout_plans_repository.dart';
import '../../models/workout_plan_model.dart';
import '../../widgets/workout_card.dart';
import '../../widgets/search_box.dart';
import 'workout_template_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _repo = WorkoutPlansRepository();
  final _searchCtrl = TextEditingController();

  // Raw data fetched once
  List<WorkoutPlanModel> _allTemplates = [];
  // Derived filtered list
  List<WorkoutPlanModel> _filtered = [];

  String? _selectedPlanType; // null = all
  String _searchTerm = '';
  bool _initialLoading = true;
  bool _error = false;

  // Category definitions (UI + corresponding backend planType)
  // NOTE: If backend does not support ENDURANCE remove or map appropriately.
  final List<_CategoryDef> _categories = const [
    _CategoryDef(
      label: 'Sức bền',
      planType: 'CARDIO',
      icon: Icons.directions_run,
      color: Color(0xFFB86B5B),
    ),
    _CategoryDef(
      label: 'Sức mạnh',
      planType: 'STRENGTH',
      icon: Icons.fitness_center,
      color: Color(0xFF7B5FB2),
    ),
    _CategoryDef(
      label: 'Kết hợp',
      planType: 'COMBINED',
      icon: Icons.timer,
      color: Color(0xFF4CB7A5),
    ),
    _CategoryDef(
      label: 'Dẻo dai',
      planType: 'FLEXIBILITY',
      icon: Icons.accessibility_new,
      color: Color(0xFF4C7CB7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _error = false;
    });
    try {
      final data = await _repo.getTemplatePlans();
      if (!mounted) return;
      _allTemplates = data;
      _applyFilters();
      setState(() {
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _error = true;
      });
    }
  }

  void _applyFilters() {
    List<WorkoutPlanModel> result = _allTemplates;
    if (_selectedPlanType != null) {
      result = result.where((p) => p.planType == _selectedPlanType).toList();
    }
    if (_searchTerm.isNotEmpty) {
      final q = _searchTerm.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    _filtered = result;
  }

  void _onSelect(String? planType) {
    if (_selectedPlanType == planType) return;
    setState(() {
      _selectedPlanType = planType;
      _applyFilters();
    });
  }

  Future<void> _refresh() async {
    try {
      final data = await _repo.getTemplatePlans();
      if (!mounted) return;
      setState(() {
        _allTemplates = data;
        _applyFilters();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        SearchBox(
          controller: _searchCtrl,
          hint: 'Tìm template...',
          variant: SearchBoxVariant.elevated,
          onChanged: (v) => setState(() {
            _searchTerm = v;
            _applyFilters();
          }),
          onClear: () => setState(() {
            _searchTerm = '';
            _applyFilters();
          }),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final c in _categories) ...[
                  Expanded(
                    child: Center(
                      child: _SelectableCategoryIcon(
                        category: c,
                        active: _selectedPlanType == c.planType,
                        onTap: () => _onSelect(
                          _selectedPlanType == c.planType ? null : c.planType,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_initialLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_error) {
                return _ExploreErrorState(onRetry: _loadInitial);
              }
              if (_filtered.isEmpty) {
                return _ExploreEmptyState(onRefresh: _loadInitial);
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                color: Colors.redAccent,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final plan = _filtered[index];
                    final subtitle =
                        '${plan.days} ngày • ${plan.exercisesCount} bài tập';
                    return WorkoutCard(
                      image: plan.picture ?? '',
                      title: plan.name,
                      subtitle: subtitle,
                      description: plan.description,
                      badge: plan.planType,
                      planType: plan.planType,
                      tags: [
                        if (plan.userName != null) 'Bởi: ${plan.userName}',
                        plan.status,
                      ],
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutTemplateScreen(plan: plan),
                          ),
                        );
                        if (result != null) {
                          // Optionally refresh or insert new plan; for now just reload data list.
                          _refresh();
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Data class for categories
class _CategoryDef {
  final String label;
  final String planType;
  final IconData icon;
  final Color color;
  const _CategoryDef({
    required this.label,
    required this.planType,
    required this.icon,
    required this.color,
  });
}

class _SelectableCategoryIcon extends StatelessWidget {
  final _CategoryDef category;
  final bool active;
  final VoidCallback onTap;
  const _SelectableCategoryIcon({
    required this.category,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = category.color;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: active
                    ? [
                        accent.withValues(alpha: .35),
                        accent.withValues(alpha: .15),
                      ]
                    : [
                        accent.withValues(alpha: .20),
                        accent.withValues(alpha: .08),
                      ],
              ),
              border: Border.all(
                color: active ? accent : Colors.white.withValues(alpha: .08),
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: .45),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .6),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Icon(
              category.icon,
              color: active ? Colors.white : accent.withValues(alpha: .9),
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.label,
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? Colors.white : Colors.white70,
              letterSpacing: .3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ExploreEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ExploreEmptyState({required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 50,
            color: Colors.white.withValues(alpha: .25),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có template',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử đổi bộ lọc hoặc tìm kiếm khác',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextButton(onPressed: onRefresh, child: const Text('Tải lại')),
        ],
      ),
    );
  }
}

class _ExploreErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ExploreErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 52,
            color: Colors.redAccent.withValues(alpha: .9),
          ),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải template',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kiểm tra mạng hoặc thử lại',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .54),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
