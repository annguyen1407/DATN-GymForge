import 'app_snack_bar.dart';
// Dùng ở: logscreen. Biểu đồ thời gian tập luyện.
import 'package:flutter/material.dart';
import '../core/extensions/color_extensions.dart';
import '../theme/design_tokens.dart';
import '../core/logging/app_logger.dart';
import '../repositories/exercise_log_repository.dart';
import '../services/api_constants.dart';

/// LogWorkoutTimeCard: Biểu đồ thống kê thời gian tập luyện theo tuần
class LogWorkoutTimeCard extends StatefulWidget {
  final String? userId;
  final String? token;
  final ExerciseLogRepository? repo;
  const LogWorkoutTimeCard({super.key, this.userId, this.token, this.repo});

  @override
  State<LogWorkoutTimeCard> createState() => _LogWorkoutTimeCardState();
}

class _LogWorkoutTimeCardState extends State<LogWorkoutTimeCard>
    with TickerProviderStateMixin {
  int currentWeekIndex = 0; // 0 = current, -1 previous weeks
  bool isLoading = false; // navigation state
  // _apiLoading reserved for future loading overlay; removed to keep analyzer clean.
  late AnimationController _animationController;
  late Animation<double> _animation;
  WeeklyExerciseStats? _weekly;
  DateTime _displayedWeekStart = _mondayOf(DateTime.now());

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _loadWeek();
  }

  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  Future<void> _loadWeek() async {
    final userId = widget.userId;
    final token = widget.token;
    if (userId == null || token == null) return; // not logged in yet
    // no-op loading state (placeholder omitted to avoid unused warnings)
    try {
      final repo =
          widget.repo ?? ExerciseLogRepository(baseUrl: ApiConstants.baseUrl);
      final stats = await repo.fetchWeeklyStats(
        userId: userId,
        weekStart: _displayedWeekStart,
        token: token,
      );
      if (!mounted) return;
      setState(() => _weekly = stats);
    } catch (e, st) {
      AppLogger.error(
        'Load weekly stats failed: $e',
        tag: 'WeeklyChart',
        error: e,
        stackTrace: st,
      );
      if (mounted) AppSnackBar.showError(context, 'Weekly stats error');
    } finally {
      // ignore - placeholder
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // mockWeeksData removed.

  // Generate date range for any week index

  Map<String, dynamic> get currentWeekData {
    final startDate = _displayedWeekStart;
    final endDate = startDate.add(const Duration(days: 6));
    final today = DateTime.now();

    final setsMap = <int, WeeklyDailyStat>{};
    for (final d in _weekly?.dailyStats ?? const <WeeklyDailyStat>[]) {
      if (d.date != null) {
        final idx = d.date!.weekday - 1;
        if (idx >= 0 && idx < 7) setsMap[idx] = d;
      }
    }

    final weekDays = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final abbrev = _weekdayAbbrev(dayDate.weekday);
      final stat = setsMap[i];
      final active = _isSameDate(dayDate, today);
      weekDays.add({
        'day': abbrev,
        'sets': (stat?.totalSets ?? 0).toDouble(),
        'active': active,
        'date': _formatDayDate(dayDate),
        'calories': stat?.totalCaloriesBurned ?? 0,
        'workoutTime': stat?.totalWorkoutTime ?? 0,
      });
    }

    return {
      'dateRange': _formatDateRange(startDate, endDate),
      'data': weekDays,
    };
  }

  // Utilities for dynamic week building
  // Legacy helper _resolveWeekStartDate removed; weekStart now tracked directly.

  // Removed date range parsing helpers (not needed with direct week tracking)

  String _weekdayAbbrev(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Mon';
    }
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  List<Map<String, dynamic>> get currentWeekWorkouts =>
      List<Map<String, dynamic>>.from(currentWeekData['data']);

  double get _totalSets => currentWeekWorkouts
      .map((day) => (day['sets'] as double))
      .fold(0.0, (a, b) => a + b);

  double get _averageSets => _totalSets / 7;

  String get _bestDay {
    double maxSets = 0;
    String best = 'Mon';
    for (final d in currentWeekWorkouts) {
      final s = d['sets'] as double;
      if (s > maxSets) {
        maxSets = s;
        best = d['day'] as String;
      }
    }
    return best;
  }

  void _navigateWeek(bool isNext) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    _animationController.reset();
    if (isNext) {
      _displayedWeekStart = _displayedWeekStart.add(const Duration(days: 7));
      currentWeekIndex++;
    } else {
      _displayedWeekStart = _displayedWeekStart.subtract(
        const Duration(days: 7),
      );
      currentWeekIndex--;
    }
    await _loadWeek();
    if (mounted) {
      setState(() => isLoading = false);
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // padding: const EdgeInsets.all(24),
      // decoration: BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: [Colors.grey[900]!, Colors.grey[850]!],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      //   borderRadius: BorderRadius.circular(24),
      //   border: Border.all(color: Colors.grey[800]!, width: 0.5),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.3),
      //       blurRadius: 16,
      //       offset: const Offset(0, 8),
      //     ),
      //   ],
      // ),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 24),
        _buildWeeklyChart(),
        const SizedBox(height: 20),
        _buildSummaryStats(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNavButton(Icons.chevron_left, () => _navigateWeek(false)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            currentWeekData['dateRange'],
            key: ValueKey(currentWeekIndex),
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        _buildNavButton(Icons.chevron_right, () => _navigateWeek(true)),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback? onPressed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: DesignTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DesignTokens.surfaceOutline.withOpacityRatio(.4),
          width: 0.5,
        ),
      ),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withOpacityRatio(0.5),
                  ),
                ),
              )
            : Icon(
                icon,
                color: isLoading
                    ? DesignTokens.textSecondary.withOpacityRatio(.3)
                    : DesignTokens.textSecondary,
                size: 18,
              ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: currentWeekWorkouts.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return _buildBarItem(
                data['day'] as String,
                data['sets'] as double,
                data['active'] as bool,
                index,
                calories: data['calories'] as int,
                workoutTime: data['workoutTime'] as int,
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarItem(
    String day,
    double sets,
    bool isActive,
    int index, {
    required int calories,
    required int workoutTime,
  }) {
    final maxHeight = 70.0;
    final maxSets = currentWeekWorkouts
        .map((d) => d['sets'] as double)
        .fold<double>(0, (p, c) => c > p ? c : p);
    final norm = maxSets <= 0 ? 0 : (sets / maxSets);
    final animated = norm * _animation.value;
    final barHeight = animated * maxHeight;

    return GestureDetector(
      onTap: () {
        final dayData = currentWeekWorkouts[index];
        final specificDate = dayData['date'] ?? day;
        _showDayDetail(
          day: day,
          sets: sets,
          calories: calories,
          workoutTime: workoutTime,
          specificDate: specificDate,
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200 + (index * 50)),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: maxHeight,
              decoration: BoxDecoration(
                color: DesignTokens.surfaceMuted.withOpacityRatio(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 500 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  width: 32,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              DesignTokens.warning.withOpacityRatio(.85),
                              DesignTokens.warning,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : const LinearGradient(
                            colors: [
                              DesignTokens.brandGradientStart,
                              DesignTokens.brandGradientEnd,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isActive
                                    ? DesignTokens.warning
                                    : DesignTokens.brand)
                                .withOpacityRatio(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              day,
              style: TextStyle(
                color: isActive
                    ? DesignTokens.warning.withOpacityRatio(.85)
                    : DesignTokens.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sets == 0 ? '0' : sets.toStringAsFixed(0),
              style: TextStyle(
                color: isActive
                    ? DesignTokens.warning.withOpacityRatio(.7)
                    : DesignTokens.textSecondary.withOpacityRatio(.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetail({
    required String day,
    required double sets,
    required int calories,
    required int workoutTime,
    required String specificDate,
  }) {
    if (sets == 0) {
      AppSnackBar.showInfo(context, 'No workout data for $specificDate');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [DesignTokens.surface, DesignTokens.surfaceAlt],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$specificDate Workout',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Sets',
                    sets.toStringAsFixed(0),
                    Icons.fitness_center,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Calo đốt',
                    calories.toString(),
                    Icons.local_fire_department,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Thời gian',
                    _formatDuration(workoutTime),
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: DesignTokens.brand, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(
        key: ValueKey(currentWeekIndex),
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Sets',
            _totalSets.toStringAsFixed(0),
            Icons.schedule_rounded,
            DesignTokens.brand,
          ),
          _buildStatItem(
            'Avg/Day',
            _averageSets.toStringAsFixed(1),
            Icons.trending_up_rounded,
            DesignTokens.success,
          ),
          _buildStatItem(
            'Best Day',
            _bestDay,
            Icons.star_rounded,
            DesignTokens.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        // Show more detailed stats
        AppSnackBar.showInfo(context, '$label: $value');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceMuted.withOpacityRatio(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignTokens.surfaceOutline.withOpacityRatio(.4),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
