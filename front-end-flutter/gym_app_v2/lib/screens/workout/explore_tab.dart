// Removed imports for template cards & sections (exclusive/quick) after cleanup.
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../repositories/workout_plans_repository.dart';
import '../../models/workout_plan_model.dart';
import '../../widgets/workout_card.dart';
import '../../widgets/plan_type_badge.dart';
import '../../widgets/search_box.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
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
  // Derived filtered lists
  List<WorkoutPlanModel> _freeTemplates = [];
  List<WorkoutPlanModel> _premiumTemplates = [];

  UserModel? _user; // to read premiumStatus

  String? _selectedPlanType; // null = all
  String _searchTerm = '';
  bool _initialLoading = true;
  bool _error = false;

  // Category definitions (UI + corresponding backend planType)
  // NOTE: If backend does not support ENDURANCE remove or map appropriately.
  final List<_CategoryDef> _categories = [
    _CategoryDef(
      label: 'Sức mạnh',
      planType: 'STRENGTH',
      icon: Icons.fitness_center, // biểu tượng tạ ~ strength
      color: PlanTypeBadge.baseColor('STRENGTH'),
    ),
    _CategoryDef(
      label: 'Sức bền',
      planType: 'CARDIO',
      icon: Icons.favorite, // tim nhịp đập tượng trưng cardio
      color: PlanTypeBadge.baseColor('CARDIO'),
    ),
    _CategoryDef(
      label: 'Dẻo dai',
      planType: 'FLEXIBILITY',
      icon: Icons.self_improvement, // tư thế yoga / stretching
      color: PlanTypeBadge.baseColor('FLEXIBILITY'),
    ),
    _CategoryDef(
      label: 'Kết hợp',
      planType: 'COMBINED',
      icon: Icons.all_inclusive, // biểu tượng vòng lặp kết hợp đa yếu tố
      color: PlanTypeBadge.baseColor('COMBINED'),
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
      final profile = await UserService.fetchProfile(context);
      final data = await _repo.getTemplatePlans();
      if (!mounted) return;
      _user = profile;
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
    // Free plans respect filters always
    Iterable<WorkoutPlanModel> baseFree = _allTemplates.where(
      (p) => !p.isPremiumOnly,
    );
    if (_selectedPlanType != null) {
      baseFree = baseFree.where((p) => p.planType == _selectedPlanType);
    }
    if (_searchTerm.isNotEmpty) {
      final q = _searchTerm.toLowerCase();
      baseFree = baseFree.where((p) => p.name.toLowerCase().contains(q));
    }
    _freeTemplates = baseFree.toList();

    // Premium plans: if user is not premium, ignore filters (show teaser set)
    final isPremiumUser = _user?.premiumStatus ?? false;
    if (!isPremiumUser) {
      _premiumTemplates = _allTemplates.where((p) => p.isPremiumOnly).toList();
    } else {
      Iterable<WorkoutPlanModel> basePremium = _allTemplates.where(
        (p) => p.isPremiumOnly,
      );
      if (_selectedPlanType != null) {
        basePremium = basePremium.where((p) => p.planType == _selectedPlanType);
      }
      if (_searchTerm.isNotEmpty) {
        final q = _searchTerm.toLowerCase();
        basePremium = basePremium.where(
          (p) => p.name.toLowerCase().contains(q),
        );
      }
      _premiumTemplates = basePremium.toList();
    }
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
      final profile = await UserService.fetchProfile(context);
      final data = await _repo.getTemplatePlans();
      if (!mounted) return;
      setState(() {
        _user = profile;
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
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside search box
        FocusScope.of(context).unfocus();
      },
      child: Column(
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
                  // "All" icon
                  Expanded(
                    child: Center(
                      child: _AllCategoryIcon(
                        active: _selectedPlanType == null,
                        onTap: () => _onSelect(null),
                      ),
                    ),
                  ),
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
                if (_freeTemplates.isEmpty && _premiumTemplates.isEmpty) {
                  return _ExploreEmptyState(onRefresh: _loadInitial);
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: Colors.redAccent,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                    children: [
                      if (_freeTemplates.isNotEmpty) ...[
                        _SectionHeader(title: 'Miễn phí'),
                        SizedBox(
                          height: 250,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final plan = _freeTemplates[index];
                              final subtitle =
                                  '${plan.days} ngày • ${plan.exercisesCount} bài tập';
                              return SizedBox(
                                width: 270,
                                child: WorkoutCard(
                                  image: plan.picture ?? '',
                                  title: plan.name,
                                  subtitle: subtitle,
                                  description: plan.description,
                                  badge: plan.planType,
                                  planType: plan.planType,
                                  tags: const [],
                                  compact: true,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            WorkoutTemplateScreen(plan: plan),
                                      ),
                                    );
                                    if (result != null) {
                                      _refresh();
                                    }
                                  },
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemCount: _freeTemplates.length,
                          ),
                        ),
                      ],
                      if (_premiumTemplates.isNotEmpty) ...[
                        _SectionHeader(title: 'Premium'),
                        SizedBox(height: 250, child: _buildPremiumList()),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ), // Close Column
    ); // Close GestureDetector
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class _AllCategoryIcon extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _AllCategoryIcon({required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final accent = Colors.blueAccent;
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
                    ? [accent.withOpacity(.35), accent.withOpacity(.15)]
                    : [accent.withOpacity(.20), accent.withOpacity(.08)],
              ),
              border: Border.all(
                color: active ? accent : Colors.white.withOpacity(.08),
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(.45),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(.6),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Icon(
              Icons.apps,
              color: active ? Colors.white : accent.withOpacity(.9),
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tất cả',
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

extension on _ExploreTabState {
  Widget _buildPremiumList() {
    final isPremium = _user?.premiumStatus ?? false;
    List<WorkoutPlanModel> display = _premiumTemplates;
    if (!isPremium && display.length > 3) {
      display = display.take(3).toList();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        final plan = display[index];
        final subtitle = '${plan.days} ngày • ${plan.exercisesCount} bài tập';
        final locked = !isPremium; // lock all premium if user not premium
        return SizedBox(
          width: 270,
          child: Stack(
            children: [
              // Card base (no text readability leak when locked due to blur overlay below)
              WorkoutCard(
                image: plan.picture ?? '',
                title: plan.name,
                subtitle: subtitle,
                description: plan.description,
                badge: plan.planType,
                planType: plan.planType,
                tags: const [],
                compact: true,
                onTap: locked
                    ? () {
                        // TODO: Optionally open upgrade bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nâng cấp Premium để truy cập kế hoạch này',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    : () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutTemplateScreen(plan: plan),
                          ),
                        );
                        if (result != null) _refresh();
                      },
              ),
              if (locked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Strong blur to hide text details
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(color: Colors.black.withOpacity(.1)),
                        ),
                        // Gradient & lock label
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(.65),
                                Colors.black.withOpacity(.30),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.lock,
                                  color: Colors.white70,
                                  size: 34,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Premium',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemCount: display.length,
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
    final accent =
        category.color; // màu đã chuẩn hoá từ PlanTypeBadge.baseColor
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
