import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
import '../../models/workout_plan_model.dart';
import '../../repositories/workout_plans_repository.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_button.dart';
import '../../repositories/workout_day_exercises_repository.dart';
import '../../repositories/exercises_repository.dart';
import '../../models/exercise_model.dart';
import '../../widgets/plan_type_badge.dart';
import '../../widgets/exercise_minimal_card.dart';
import '../exercise/exercise_info_screen.dart';

/// Chi tiết template workout plan.
class WorkoutTemplateScreen extends StatefulWidget {
  final WorkoutPlanModel plan;
  const WorkoutTemplateScreen({super.key, required this.plan});

  @override
  State<WorkoutTemplateScreen> createState() => _WorkoutTemplateScreenState();
}

class _WorkoutTemplateScreenState extends State<WorkoutTemplateScreen> {
  final _repo = WorkoutPlansRepository();
  final _dayExerciseRepo = WorkoutDayExercisesRepository();
  final _exerciseRepo = ExercisesRepository();
  WorkoutPlanModel? _detail;
  bool _loading = true;
  bool _error = false;

  // exercises
  bool _loadingExercises = true;
  List<ExerciseModel> _exercises = [];
  bool _cloning = false;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.plan;
    _fetch();
    _fetchExercises();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final res = await _repo.getPlan(widget.plan.id);
    if (!mounted) return;
    setState(() {
      if (res != null) _detail = res;
      _loading = false;
      _error = res == null;
    });
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _loadingExercises = true;
    });
    try {
      final list = await _dayExerciseRepo.getByWorkoutPlan(widget.plan.id);
      // unique exercise ids
      final ids = list.map((e) => e.exerciseId).toSet().toList();
      final result = <ExerciseModel>[];
      for (final id in ids) {
        final ex = await _exerciseRepo.getById(id);
        if (ex != null) result.add(ex);
      }
      if (!mounted) return;
      setState(() {
        _exercises = result;
        _loadingExercises = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exercises = [];
        _loadingExercises = false;
      });
    }
  }

  Future<void> _cloneTemplate() async {
    final template = _detail ?? widget.plan;
    if (_cloning) return;
    setState(() => _cloning = true);
    try {
      // Always use the current logged-in user's id (not the template owner)
      final UserModel? me = await UserService.fetchProfile(context);
      if (me == null) {
        if (!mounted) return;
        AppSnackBar.showError(context, 'Không lấy được thông tin người dùng');
        return;
      }
      final cloned = await _repo.cloneTemplate(
        templateId: template.id,
        userId: me.id,
        name: template.name,
        description: template.description ?? '',
      );
      if (!mounted) return;
      if (cloned != null) {
        AppSnackBar.showSuccess(context, 'Đã tạo kế hoạch');
        Navigator.pop(context, cloned);
      } else {
        AppSnackBar.showError(context, 'Tạo kế hoạch thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('403')
          ? 'Bạn chỉ có thể tạo kế hoạch cho chính bạn'
          : 'Lỗi: $e';
      AppSnackBar.showError(context, msg);
    } finally {
      if (mounted) setState(() => _cloning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _detail ?? widget.plan;
    final exercisesCount = _exercises.length; // override if loaded
    final totalHeight = MediaQuery.of(context).size.height;
    const bottomBarHeight = 84.0; // approx including safe area
    const headerHeight = 250.0; // reduced
    final availableListHeight =
        totalHeight - bottomBarHeight - headerHeight - 295;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  planName: plan.name,
                  height: headerHeight,
                  planType: plan.planType,
                  days: plan.days,
                  exercises: _loadingExercises ? null : exercisesCount,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      if (plan.description?.isNotEmpty == true) ...[
                        _DescriptionSection(
                          text: plan.description!,
                          expanded: _showFullDescription,
                          onToggle: () => setState(
                            () => _showFullDescription = !_showFullDescription,
                          ),
                        ),
                        const SizedBox(height: 26),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bài tập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacityRatio(.95),
                            ),
                          ),
                          Text(
                            _loadingExercises ? '...' : '$exercisesCount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacityRatio(.55),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: availableListHeight < 220
                            ? 220
                            : availableListHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF19191D), Color(0xFF141416)],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacityRatio(.04),
                          ),
                        ),
                        child: _loadingExercises
                            ? const Center(child: CircularProgressIndicator())
                            : _exercises.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có bài tập',
                                  style: TextStyle(
                                    color: Colors.white.withOpacityRatio(.65),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  14,
                                ),
                                itemCount: _exercises.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (c, i) => ExerciseMinimalCard(
                                  exercise: _exercises[i],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ExerciseInfoScreen(
                                          exerciseId: _exercises[i].id,
                                        ),
                                      ),
                                    );
                                  },
                                  dense: false,
                                ),
                              ),
                      ),
                      const SizedBox(height: 28),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error)
                        _ErrorInline(onRetry: _fetch),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacityRatio(.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacityRatio(.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacityRatio(.55),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x000F0F11), Color(0xCC0F0F11)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: AppButton.primary(
                  label: _cloning ? 'Đang tạo...' : 'Dùng template này',
                  onPressed: _cloning ? null : _cloneTemplate,
                  size: AppButtonSize.large,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// New custom header widget
class _Header extends StatelessWidget {
  final String planName;
  final double height;
  final String planType;
  final int days;
  final int? exercises; // null while loading
  const _Header({
    required this.planName,
    required this.planType,
    required this.days,
    this.exercises,
    this.height = 170,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF23232A), Color(0xFF141417)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -40,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacityRatio(.08),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacityRatio(.07),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  planName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    PlanTypeBadge(planType: planType),
                    _DaysBadge(days: days),
                    if (exercises != null) _ExercisesBadge(count: exercises!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  final int days;
  const _DaysBadge({required this.days});
  @override
  Widget build(BuildContext context) {
    return _BaseBadge(
      gradient: const [Color(0xFF2E2E35), Color(0xFF1B1B1F)],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            '$days ngày',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacityRatio(.92),
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BaseBadge extends StatelessWidget {
  final List<Color> gradient;
  final Widget child;
  const _BaseBadge({required this.gradient, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: Colors.white.withOpacityRatio(.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityRatio(.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Re-introduced description card (was accidentally removed during refactor)
// _DescriptionCard removed: description now inline (AnimatedSize) per new design.

class _ExercisesBadge extends StatelessWidget {
  final int count;
  const _ExercisesBadge({required this.count});
  @override
  Widget build(BuildContext context) {
    return _BaseBadge(
      gradient: const [Color(0xFF2E2532), Color(0xFF1A1920)],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.list_alt_rounded, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            '$count bài tập',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacityRatio(.92),
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorInline extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorInline({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 44,
          color: Colors.redAccent.withOpacityRatio(.9),
        ),
        const SizedBox(height: 12),
        const Text(
          'Không tải được chi tiết',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}

// (Đã bỏ header cũ với các vòng tròn trang trí)

// Exercise card
// _ExerciseCard removed; replaced by shared ExerciseMinimalCard.

class _DescriptionSection extends StatefulWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  const _DescriptionSection({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _overflow = false;
  static const _maxLinesCollapsed = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measureOverflow();
  }

  @override
  void didUpdateWidget(covariant _DescriptionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _measureOverflow();
    }
  }

  void _measureOverflow() {
    final tp = TextPainter(
      text: TextSpan(
        text: widget.text.trim(),
        style: TextStyle(
          fontSize: 14.2,
          height: 1.52,
          color: Colors.white.withOpacityRatio(.84),
          letterSpacing: .25,
        ),
      ),
      maxLines: _maxLinesCollapsed,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    );
    final maxWidth =
        MediaQuery.of(context).size.width - 40; // padding 20 left/right
    tp.layout(maxWidth: maxWidth);
    if (mounted) {
      setState(() => _overflow = tp.didExceedMaxLines);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.text.trim();
    final showToggle = _overflow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: showToggle ? 8 : 0),
                child: Text(
                  displayText,
                  softWrap: true,
                  maxLines: widget.expanded ? null : _maxLinesCollapsed,
                  overflow: widget.expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.2,
                    height: 1.52,
                    color: Colors.white.withOpacityRatio(.84),
                    letterSpacing: .25,
                  ),
                ),
              ),
              if (showToggle && !widget.expanded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.10),
                            Colors.black.withOpacity(0.22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showToggle)
          GestureDetector(
            onTap: widget.onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.expanded ? 'Thu gọn' : 'Xem thêm',
                  style: const TextStyle(
                    color: Color(0xFFFF4E74),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 240),
                  turns: widget.expanded ? 0.5 : 0.0,
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.expand_more,
                    size: 18,
                    color: Color(0xFFFF4E74),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
