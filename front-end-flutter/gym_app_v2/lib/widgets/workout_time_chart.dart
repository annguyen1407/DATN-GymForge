import 'app_snack_bar.dart';
import 'package:flutter/material.dart';
import '../core/extensions/color_extensions.dart';
import '../repositories/exercise_log_repository.dart';
import '../services/api_constants.dart';
import '../core/logging/app_logger.dart';

/// WorkoutTimeChart: Weekly workout stats chart (now API-driven, using sets)
class WorkoutTimeChart extends StatefulWidget {
  final String? userId;
  final String? token;
  final ExerciseLogRepository? repo;
  const WorkoutTimeChart({super.key, this.userId, this.token, this.repo});

  @override
  State<WorkoutTimeChart> createState() => _WorkoutTimeChartState();
}

class _WorkoutTimeChartState extends State<WorkoutTimeChart>
    with TickerProviderStateMixin {
  int currentWeekIndex =
      0; // 0 = current week, negative = past, positive = future
  bool isLoading = false; // week navigation state
  late AnimationController _animationController;
  late Animation<double> _animation;
  WeeklyExerciseStats? _weekly; // current fetched week stats
  DateTime _displayedWeekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

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

  Future<void> _loadWeek() async {
    final userId = widget.userId;
    final token = widget.token;
    if (userId == null || token == null) {
      return; // unauthenticated => keep empty chart
    }
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
        'Home weekly stats load failed: $e',
        tag: 'WorkoutTimeChart',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _generateDateRange() {
    final start = _displayedWeekStart;
    final end = start.add(const Duration(days: 6));
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

  String _weekdayLabel(int wd) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][wd - 1];

  Map<String, dynamic> get currentWeekData {
    final start = _displayedWeekStart;
    final today = DateTime.now();
    final setsMap = <int, WeeklyDailyStat>{};
    for (final d in _weekly?.dailyStats ?? const <WeeklyDailyStat>[]) {
      if (d.date != null) {
        final idx = d.date!.weekday - 1;
        if (idx >= 0 && idx < 7) setsMap[idx] = d;
      }
    }
    final data = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final dayDate = start.add(Duration(days: i));
      final stat = setsMap[i];
      data.add({
        'day': _weekdayLabel(dayDate.weekday),
        'sets': (stat?.totalSets ?? 0).toDouble(),
        'calories': stat?.totalCaloriesBurned ?? 0,
        'workoutTime': stat?.totalWorkoutTime ?? 0,
        'active':
            dayDate.year == today.year &&
            dayDate.month == today.month &&
            dayDate.day == today.day,
        'date':
            '${dayDate.day.toString().padLeft(2, '0')}/${dayDate.month.toString().padLeft(2, '0')}',
      });
    }
    return {'dateRange': _generateDateRange(), 'data': data};
  }

  List<Map<String, dynamic>> get currentWeekWorkouts =>
      List<Map<String, dynamic>>.from(currentWeekData['data']);
  double get totalSets => currentWeekWorkouts
      .map((d) => d['sets'] as double)
      .fold(0.0, (a, b) => a + b);
  double get averageSets => totalSets / 7;
  String get bestDay {
    String best = 'Mon';
    double max = 0;
    for (final d in currentWeekWorkouts) {
      if (d['sets'] > max) {
        max = d['sets'];
        best = d['day'];
      }
    }
    return best;
  }

  void _navigateWeek(bool isNext) async {
    if (isLoading) return;
    setState(() => isLoading = true);
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
    if (!mounted) return;
    setState(() => isLoading = false);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[800]!, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityRatio(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          _buildWeeklyChart(),
          const SizedBox(height: 20),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Workout Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacityRatio(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Weekly View',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
              color: Colors.white70,
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
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[700]!, width: 0.5),
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
                color: isLoading ? Colors.white30 : Colors.white70,
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
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarItem(String day, double sets, bool isActive, int index) {
    final maxHeight = 70.0;
    final maxSets = currentWeekWorkouts
        .map((d) => d['sets'] as double)
        .fold<double>(0, (p, c) => c > p ? c : p);
    final norm = maxSets <= 0 ? 0 : (sets / maxSets);
    final barHeight = norm * maxHeight * _animation.value;

    return GestureDetector(
      onTap: () {
        // Show detail popup with specific date
        final dayData = currentWeekWorkouts[index];
        final specificDate = dayData['date'] ?? day;
        _showDayDetail(day, sets, specificDate, dayData);
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
                color: Colors.grey[800]!.withOpacityRatio(0.3),
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
                            // Màu cam cho ngày hiện tại/được chọn
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : LinearGradient(
                            // Màu tím cho ngày bình thường
                            colors: [
                              Colors.purple.shade400,
                              Colors.purple.shade600,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? Colors.orange : Colors.purple)
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
                color: isActive ? Colors.orange.shade300 : Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sets == 0 ? '0' : sets.toStringAsFixed(0),
              style: TextStyle(
                color: isActive
                    ? Colors.orange.shade200
                    : Colors.white.withOpacityRatio(0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  void _showDayDetail(
    String day,
    double sets,
    String specificDate,
    Map<String, dynamic> raw,
  ) {
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
            colors: [Colors.grey[900]!, Colors.grey[850]!],
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
                    (raw['calories'] ?? 0).toString(),
                    Icons.local_fire_department,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Thời gian',
                    _formatDuration(raw['workoutTime'] ?? 0),
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

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.purple.shade400, size: 24),
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
            totalSets.toStringAsFixed(0),
            Icons.fitness_center,
            Colors.purple.shade400,
          ),
          _buildStatItem(
            'Avg/Day',
            averageSets.toStringAsFixed(1),
            Icons.trending_up_rounded,
            Colors.green.shade400,
          ),
          _buildStatItem(
            'Best Day',
            bestDay,
            Icons.star_rounded,
            Colors.orange.shade400,
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
          color: Colors.grey[800]!.withOpacityRatio(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
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
