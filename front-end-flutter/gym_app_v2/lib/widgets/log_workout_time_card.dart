import 'app_snack_bar.dart';
// Dùng ở: logscreen. Biểu đồ thời gian tập luyện.
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// LogWorkoutTimeCard: Biểu đồ thống kê thời gian tập luyện theo tuần
class LogWorkoutTimeCard extends StatefulWidget {
  const LogWorkoutTimeCard({super.key});

  @override
  State<LogWorkoutTimeCard> createState() => _LogWorkoutTimeCardState();
}

class _LogWorkoutTimeCardState extends State<LogWorkoutTimeCard>
    with TickerProviderStateMixin {
  int currentWeekIndex = 32; // Start with current week (8/8/2025)
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Set current week index based on today's date
    currentWeekIndex = _getCurrentWeekIndex();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  // Tính toán week index dựa trên ngày hiện tại
  int _getCurrentWeekIndex() {
    final now = DateTime.now(); // 8/8/2025 = Friday

    // 8/8/2025 nằm trong tuần 4-10 Aug (week 32)
    // Kiểm tra: 4/8 = Monday, 8/8 = Friday
    if (now.year == 2025 && now.month == 8 && now.day >= 4 && now.day <= 10) {
      return 32;
    }

    // Fallback calculation cho các ngày khác
    final baseDate = DateTime(2025, 1, 6); // Monday of week 1
    final diffInDays = now.difference(baseDate).inDays;
    return 1 + (diffInDays / 7).floor();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Mock data cho một số tuần - các tuần khác sẽ trống
  final Map<int, Map<String, dynamic>> mockWeeksData = {
    // Tuần xa (để test)
    0: {
      'dateRange': '28 Dec - 3 Jan 2025',
      'data': [
        {'day': 'Mon', 'hours': 1.8, 'active': false, 'date': '30 Dec'},
        {'day': 'Tue', 'hours': 2.5, 'active': false, 'date': '31 Dec'},
        {'day': 'Wed', 'hours': 1.2, 'active': false, 'date': '1 Jan'},
        {'day': 'Thu', 'hours': 3.0, 'active': false, 'date': '2 Jan'},
        {'day': 'Fri', 'hours': 2.2, 'active': false, 'date': '3 Jan'},
        {'day': 'Sat', 'hours': 1.8, 'active': false, 'date': '4 Jan'},
        {'day': 'Sun', 'hours': 0.5, 'active': false, 'date': '28 Dec'},
      ],
    },
    1: {
      'dateRange': '4 Jan - 10 Jan 2025',
      'data': [
        {'day': 'Mon', 'hours': 2.2, 'active': false, 'date': '6 Jan'},
        {'day': 'Tue', 'hours': 3.0, 'active': false, 'date': '7 Jan'},
        {'day': 'Wed', 'hours': 2.8, 'active': false, 'date': '8 Jan'},
        {'day': 'Thu', 'hours': 1.8, 'active': false, 'date': '9 Jan'},
        {'day': 'Fri', 'hours': 2.5, 'active': false, 'date': '10 Jan'},
        {'day': 'Sat', 'hours': 1.2, 'active': false, 'date': '11 Jan'},
        {'day': 'Sun', 'hours': 1.5, 'active': false, 'date': '5 Jan'},
      ],
    },

    // Tuần xung quanh tuần hiện tại (week 32: 4-10 Aug 2025)
    29: {
      'dateRange': '14 Jul - 20 Jul 2025',
      'data': [
        {'day': 'Mon', 'hours': 2.5, 'active': false, 'date': '14 Jul'},
        {'day': 'Tue', 'hours': 1.8, 'active': false, 'date': '15 Jul'},
        {'day': 'Wed', 'hours': 3.2, 'active': false, 'date': '16 Jul'},
        {'day': 'Thu', 'hours': 2.0, 'active': false, 'date': '17 Jul'},
        {'day': 'Fri', 'hours': 2.8, 'active': false, 'date': '18 Jul'},
        {'day': 'Sat', 'hours': 1.5, 'active': false, 'date': '19 Jul'},
        {'day': 'Sun', 'hours': 1.0, 'active': false, 'date': '20 Jul'},
      ],
    },
    30: {
      'dateRange': '21 Jul - 27 Jul 2025',
      'data': [
        {'day': 'Mon', 'hours': 2.0, 'active': false, 'date': '21 Jul'},
        {'day': 'Tue', 'hours': 2.5, 'active': false, 'date': '22 Jul'},
        {'day': 'Wed', 'hours': 1.5, 'active': false, 'date': '23 Jul'},
        {'day': 'Thu', 'hours': 3.0, 'active': false, 'date': '24 Jul'},
        {'day': 'Fri', 'hours': 2.2, 'active': false, 'date': '25 Jul'},
        {'day': 'Sat', 'hours': 1.8, 'active': false, 'date': '26 Jul'},
        {'day': 'Sun', 'hours': 0.0, 'active': false, 'date': '27 Jul'},
      ],
    },
    31: {
      'dateRange': '28 Jul - 3 Aug 2025',
      'data': [
        {'day': 'Mon', 'hours': 2.8, 'active': false, 'date': '28/07/2025'},
        {'day': 'Tue', 'hours': 2.0, 'active': false, 'date': '29/07/2025'},
        {'day': 'Wed', 'hours': 1.8, 'active': false, 'date': '30/07/2025'},
        {'day': 'Thu', 'hours': 2.5, 'active': false, 'date': '31/07/2025'},
        {'day': 'Fri', 'hours': 3.2, 'active': false, 'date': '01/08/2025'},
        {'day': 'Sat', 'hours': 1.0, 'active': false, 'date': '02/08/2025'},
        {'day': 'Sun', 'hours': 1.2, 'active': false, 'date': '03/08/2025'},
      ],
    },

    // Tuần hiện tại (8/8/2025 = Friday)
    32: {
      'dateRange': '4 Aug - 10 Aug 2025',
      'data': [
        {
          'day': 'Mon',
          'hours': 2.0,
          'active': false,
          'date': '04/08/2025',
        }, // Thứ 2 đầu tiên
        {'day': 'Tue', 'hours': 2.8, 'active': false, 'date': '05/08/2025'},
        {'day': 'Wed', 'hours': 1.8, 'active': false, 'date': '06/08/2025'},
        {'day': 'Thu', 'hours': 2.5, 'active': false, 'date': '07/08/2025'},
        {
          'day': 'Fri',
          'hours': 2.2,
          'active': false,
          'date': '08/08/2025',
        }, // Hôm nay 8/8/2025 = Friday
        {
          'day': 'Sat',
          'hours': 0.0,
          'active': false,
          'date': '09/08/2025',
        }, // Chưa diễn ra
        {
          'day': 'Sun',
          'hours': 1.5,
          'active': false,
          'date': '10/08/2025',
        }, // Chủ nhật cuối cùng
      ],
    },

    // Tuần sau
    33: {
      'dateRange': '11 Aug - 17 Aug 2025',
      'data': [
        {
          'day': 'Mon',
          'hours': 0.0,
          'active': false,
          'date': '11/08/2025',
        }, // Tuần tương lai
        {'day': 'Tue', 'hours': 0.0, 'active': false, 'date': '12/08/2025'},
        {'day': 'Wed', 'hours': 0.0, 'active': false, 'date': '13/08/2025'},
        {'day': 'Thu', 'hours': 0.0, 'active': false, 'date': '14/08/2025'},
        {'day': 'Fri', 'hours': 0.0, 'active': false, 'date': '15/08/2025'},
        {'day': 'Sat', 'hours': 0.0, 'active': false, 'date': '16/08/2025'},
        {'day': 'Sun', 'hours': 0.0, 'active': false, 'date': '17/08/2025'},
      ],
    },
    34: {
      'dateRange': '18 Aug - 24 Aug 2025',
      'data': [
        {'day': 'Mon', 'hours': 0.0, 'active': false, 'date': '18 Aug'},
        {'day': 'Tue', 'hours': 0.0, 'active': false, 'date': '19 Aug'},
        {'day': 'Wed', 'hours': 0.0, 'active': false, 'date': '20 Aug'},
        {'day': 'Thu', 'hours': 0.0, 'active': false, 'date': '21 Aug'},
        {'day': 'Fri', 'hours': 0.0, 'active': false, 'date': '22 Aug'},
        {'day': 'Sat', 'hours': 0.0, 'active': false, 'date': '23 Aug'},
        {'day': 'Sun', 'hours': 0.0, 'active': false, 'date': '24 Aug'},
      ],
    },
    35: {
      'dateRange': '25 Aug - 31 Aug 2025',
      'data': [
        {'day': 'Mon', 'hours': 0.0, 'active': false, 'date': '25 Aug'},
        {'day': 'Tue', 'hours': 0.0, 'active': false, 'date': '26 Aug'},
        {'day': 'Wed', 'hours': 0.0, 'active': false, 'date': '27 Aug'},
        {'day': 'Thu', 'hours': 0.0, 'active': false, 'date': '28 Aug'},
        {'day': 'Fri', 'hours': 0.0, 'active': false, 'date': '29 Aug'},
        {'day': 'Sat', 'hours': 0.0, 'active': false, 'date': '30 Aug'},
        {'day': 'Sun', 'hours': 0.0, 'active': false, 'date': '31 Aug'},
      ],
    },
  };

  // Generate date range for any week index

  Map<String, dynamic> get currentWeekData {
    // Determine start Monday for current index
    final startDate = _resolveWeekStartDate(currentWeekIndex);
    final endDate = startDate.add(const Duration(days: 6));
    final isCurrentWeek = currentWeekIndex == _getCurrentWeekIndex();
    final today = DateTime.now();

    // Build hours map from mock (if available) keyed by weekday abbrev
    final hoursMap = <String, double>{};
    if (mockWeeksData.containsKey(currentWeekIndex)) {
      final raw = mockWeeksData[currentWeekIndex]!['data'] as List<dynamic>;
      for (final d in raw) {
        if (d is Map<String, dynamic>) {
          final wd = d['day'];
          if (wd is String && d['hours'] is num) {
            hoursMap[wd] = (d['hours'] as num).toDouble();
          }
        }
      }
    }

    final weekDays = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final abbrev = _weekdayAbbrev(dayDate.weekday);
      final hours = hoursMap[abbrev] ?? 0.0;
      final active = isCurrentWeek && _isSameDate(dayDate, today);
      weekDays.add({
        'day': abbrev,
        'hours': hours,
        'active': active,
        'date': _formatDayDate(dayDate),
      });
    }

    return {
      'dateRange': _formatDateRange(startDate, endDate),
      'data': weekDays,
    };
  }

  // Utilities for dynamic week building
  DateTime _resolveWeekStartDate(int weekIndex) {
    // If we have mock dateRange, parse its first date to ensure alignment
    if (mockWeeksData.containsKey(weekIndex)) {
      final dr = mockWeeksData[weekIndex]!['dateRange'] as String?;
      final parsed = _parseDateRangeStart(dr);
      if (parsed != null) return parsed;
    }
    // Reference: week 32 starts at 4 Aug 2025 (Monday) from existing mock
    final referenceMonday = DateTime(2025, 8, 4);
    final diffWeeks = weekIndex - 32;
    return referenceMonday.add(Duration(days: diffWeeks * 7));
  }

  DateTime? _parseDateRangeStart(String? dateRange) {
    if (dateRange == null) return null;
    // Pattern e.g. '4 Aug - 10 Aug 2025'
    final parts = dateRange.split(' - ');
    if (parts.length != 2) return null;
    final startPart = parts[0].trim(); // '4 Aug'
    final endPart = parts[1].trim(); // '10 Aug 2025'
    final endTokens = endPart.split(' ');
    if (endTokens.length < 3) return null;
    final year = int.tryParse(endTokens.last);
    if (year == null) return null;
    final startTokens = startPart.split(' ');
    if (startTokens.length != 2) return null;
    final startDay = int.tryParse(startTokens[0]);
    final monthStr = startTokens[1];
    final month = _monthFromAbbrev(monthStr);
    if (startDay == null || month == null) return null;
    return DateTime(year, month, startDay);
  }

  int? _monthFromAbbrev(String m) {
    const map = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return map[m];
  }

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

  double get totalHours => currentWeekWorkouts
      .map((day) => day['hours'] as double)
      .reduce((a, b) => a + b);

  double get averageHours => totalHours / 7;

  String get bestDay {
    final maxHours = currentWeekWorkouts
        .map((day) => day['hours'] as double)
        .reduce((a, b) => a > b ? a : b);

    return currentWeekWorkouts.firstWhere(
      (day) => day['hours'] == maxHours,
    )['day'];
  }

  void _navigateWeek(bool isNext) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // Reset animation
    _animationController.reset();

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      if (isNext) {
        currentWeekIndex++;
      } else {
        currentWeekIndex--;
      }
      isLoading = false;
    });

    // Start animation
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          _buildWeeklyChart(),
          const SizedBox(height: 20),
          _buildSummaryStats(),
        ],
      ),
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
          color: DesignTokens.surfaceOutline.withOpacity(.4),
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
                    Colors.white.withOpacity(0.5),
                  ),
                ),
              )
            : Icon(
                icon,
                color: isLoading
                    ? DesignTokens.textSecondary.withOpacity(.3)
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
                data['hours'] as double,
                data['active'] as bool,
                index,
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarItem(String day, double hours, bool isActive, int index) {
    final maxHeight = 70.0;
    final animatedHours = hours * _animation.value;
    final barHeight = (animatedHours / 3.5) * maxHeight;

    return GestureDetector(
      onTap: () {
        // Show detail popup with specific date
        final dayData = currentWeekWorkouts[index];
        final specificDate = dayData['date'] ?? day;
        _showDayDetail(day, hours, specificDate);
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
                color: DesignTokens.surfaceMuted.withOpacity(0.3),
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
                              DesignTokens.warning.withOpacity(.85),
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
                                .withOpacity(0.4),
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
                    ? DesignTokens.warning.withOpacity(.85)
                    : DesignTokens.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${hours.toStringAsFixed(1)}h',
              style: TextStyle(
                color: isActive
                    ? DesignTokens.warning.withOpacity(.7)
                    : DesignTokens.textSecondary.withOpacity(.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetail(String day, double hours, String specificDate) {
    // Don't show detail for empty days
    if (hours == 0) {
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
                    'Số giờ tập',
                    '${hours.toStringAsFixed(1)}h',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Calo đốt',
                    '${(hours * 300).toInt()}',
                    Icons.local_fire_department,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Workout Sets',
                    '${(hours * 3).toInt()}',
                    Icons.fitness_center,
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
            'Total Hours',
            '${totalHours.toStringAsFixed(1)}h',
            Icons.schedule_rounded,
            DesignTokens.brand,
          ),
          _buildStatItem(
            'Avg/Day',
            '${averageHours.toStringAsFixed(1)}h',
            Icons.trending_up_rounded,
            DesignTokens.success,
          ),
          _buildStatItem(
            'Best Day',
            bestDay,
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
          color: DesignTokens.surfaceMuted.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignTokens.surfaceOutline.withOpacity(.4),
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
