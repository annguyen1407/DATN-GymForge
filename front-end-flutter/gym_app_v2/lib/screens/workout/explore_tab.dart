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
  Future<List<WorkoutPlanModel>>? _future;
  String? _currentFilter; // current selected planType or null = all
  String _search = '';
  final _searchCtrl = TextEditingController();

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
    _fetch();
  }

  void _fetch() {
    setState(() {
      _future = _repo.getTemplatePlans(planType: _currentFilter);
    });
  }

  Future<void> _refresh() async {
    _fetch();
    final f = _future;
    if (f != null) await f;
  }

  void _onSelect(String? planType) {
    if (_currentFilter == planType) return; // no change
    _currentFilter = planType;
    _fetch();
  }

  List<WorkoutPlanModel> _applySearch(List<WorkoutPlanModel> data) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return data;
    return data.where((p) => p.name.toLowerCase().contains(q)).toList();
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
          onChanged: (v) => setState(() => _search = v),
          onClear: () => setState(() => _search = ''),
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
                        active: _currentFilter == c.planType,
                        onTap: () => _onSelect(
                          _currentFilter == c.planType ? null : c.planType,
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
          child: FutureBuilder<List<WorkoutPlanModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ExploreErrorState(onRetry: _refresh);
              }
              final data = _applySearch(snapshot.data ?? []);
              if (data.isEmpty) {
                return _ExploreEmptyState(onRefresh: _refresh);
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                color: Colors.redAccent,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final plan = data[index];
                    final subtitleParts = <String>[];
                    subtitleParts.add('${plan.days} ngày');
                    subtitleParts.add('${plan.exercisesCount} bài tập');
                    final subtitle = subtitleParts.join(' • ');
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutTemplateScreen(plan: plan),
                          ),
                        );
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
