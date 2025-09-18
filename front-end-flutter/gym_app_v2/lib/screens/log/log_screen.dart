import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart'; // Added for line chart
import '../../widgets/stats_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/log_workout_time_card.dart';
import 'workout_details_page.dart';

/// LogScreen: Tab "Log" hiển thị lịch sử tập luyện, thống kê, các nhóm workout đã hoàn thành
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen>
    with SingleTickerProviderStateMixin {
  // State variable to track the selected tab
  String _selectedTab = 'Lịch sử';

  // TabController for TabBar
  late TabController _tabController;

  // State variables for body metrics (placeholder values)
  double _weight = 70.0; // kg
  double _height = 175.0; // cm
  final double _bodyFat = 20.0; // percentage
  double _oneRepMax = 100.0; // kg

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // State for toggling between LogWorkoutTimeCard and TableCalendar
  bool _showWorkoutTimeCard = true;

  // Mock workout data (replace with backend data)
  final Map<DateTime, List<Map<String, dynamic>>> _workouts = {
    DateTime(2025, 8, 1): [
      {'name': 'Bench Press', 'sets': 3, 'reps': 10, 'weight': 80.0},
      {'name': 'Squats', 'sets': 4, 'reps': 12, 'weight': 100.0},
    ],
    DateTime(2025, 8, 2): [
      {'name': 'Deadlift', 'sets': 3, 'reps': 8, 'weight': 120.0},
      {'name': 'Pull-Ups', 'sets': 3, 'reps': 15, 'weight': 0.0},
    ],
  };

  // Mock historical data for Weight and 1RM (replace with backend data)
  final List<Map<String, dynamic>> _bodyMetricsHistory = [
    {
      'week': 1,
      'date': DateTime(2025, 8, 4),
      'weight': 70.0,
      'oneRepMax': 100.0,
    },
    {
      'week': 2,
      'date': DateTime(2025, 8, 11),
      'weight': 69.5,
      'oneRepMax': 102.0,
    },
    {
      'week': 3,
      'date': DateTime(2025, 8, 18),
      'weight': 69.0,
      'oneRepMax': 104.0,
    },
    {
      'week': 4,
      'date': DateTime(2025, 8, 25),
      'weight': 68.8,
      'oneRepMax': 105.0,
    },
    {
      'week': 5,
      'date': DateTime(2025, 9, 1),
      'weight': 68.5,
      'oneRepMax': 106.0,
    },
    {
      'week': 6,
      'date': DateTime(2025, 9, 8),
      'weight': 68.0,
      'oneRepMax': 108.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize TabController
    _tabController = TabController(length: 2, vsync: this);
    // Sync TabController with _selectedTab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index == 0 ? 'Lịch sử' : 'Chuyên sâu';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to toggle between LogWorkoutTimeCard and TableCalendar
  void _toggleHistoryView(bool showWorkoutTimeCard) {
    setState(() {
      _showWorkoutTimeCard = showWorkoutTimeCard;
    });
  }

  // Function to handle new workout addition
  void _addWorkout(DateTime date, Map<String, dynamic> workout) {
    setState(() {
      if (_workouts.containsKey(date)) {
        _workouts[date]!.add(workout);
      } else {
        _workouts[date] = [workout];
      }
    });
  }

  // Function to show bottom sheet for updating body metrics
  Future<void> _showBodyMetricsUpdateModal(BuildContext context) async {
    TextEditingController weightController = TextEditingController();
    TextEditingController heightController = TextEditingController();
    TextEditingController oneRepMaxController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Body Metrics',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                labelStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white54),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF8854FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                labelStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white54),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF8854FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: oneRepMaxController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'One-Rep Max (kg)',
                labelStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white54),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF8854FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppButton.text(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    fullWidth: true,
                    size: AppButtonSize.small,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.primary(
                    label: 'Save',
                    size: AppButtonSize.small,
                    onPressed: () {
                      // Validate and update weight
                      final weightInput = weightController.text;
                      final newWeight = double.tryParse(weightInput);
                      if (newWeight != null && newWeight > 0) {
                        setState(() {
                          _weight = newWeight;
                          // Update historical data (example)
                          _bodyMetricsHistory.add({
                            'week': _bodyMetricsHistory.length + 1,
                            'date': DateTime.now(),
                            'weight': newWeight,
                            'oneRepMax': _oneRepMax,
                          });
                        });
                      }
                      // Validate and update height
                      final heightInput = heightController.text;
                      final newHeight = double.tryParse(heightInput);
                      if (newHeight != null && newHeight > 0) {
                        setState(() {
                          _height = newHeight;
                        });
                      }
                      // Validate and update 1RM
                      final oneRepMaxInput = oneRepMaxController.text;
                      final newOneRepMax = double.tryParse(oneRepMaxInput);
                      if (newOneRepMax != null && newOneRepMax > 0) {
                        setState(() {
                          _oneRepMax = newOneRepMax;
                          // Update historical data (example)
                          _bodyMetricsHistory[_bodyMetricsHistory.length -
                                  1]['oneRepMax'] =
                              newOneRepMax;
                        });
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // TabBar for Lịch sử and Chuyên sâu
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Lịch sử'),
                Tab(text: 'Chuyên sâu'),
              ],
              indicatorColor: Color(0xFF8854FF),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 8,
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: _selectedTab == 'Lịch sử'
                    ? _buildHistoryContent()
                    : _buildInDepthContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Content for "Lịch sử" tab
  Widget _buildHistoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thống kê tổng quan
        const StatsCard(),
        const SizedBox(height: 24),
        // Danh sách nhóm workout đã hoàn thành
        const Text(
          'Workout sets',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your completed workout categories',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            CategoryIcon(
              icon: Icons.directions_run,
              color: Color(0xFFB86B5B),
              label: 'Cardio',
              count: 3,
            ),
            CategoryIcon(
              icon: Icons.fitness_center,
              color: Color(0xFF7B5FB2),
              label: 'Strength',
              count: 2,
            ),
            CategoryIcon(
              icon: Icons.timer,
              color: Color(0xFF4CB7A5),
              label: 'Endurance',
              count: 2,
            ),
            CategoryIcon(
              icon: Icons.more_horiz,
              color: Color(0xFF4C7CB7),
              label: 'More',
              count: 3,
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Workout History Section (toggling between LogWorkoutTimeCard and Calendar)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workout time',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your daily workout progress',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Toggle Buttons
              Center(
                child: Container(
                  height: 32,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleHistoryView(true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _showWorkoutTimeCard
                                  ? const Color(0xFF8854FF)
                                  : Colors.grey[800],
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(8),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Ngày',
                              style: TextStyle(
                                color: _showWorkoutTimeCard
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: Colors.grey[700]),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleHistoryView(false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_showWorkoutTimeCard
                                  ? const Color(0xFF8854FF)
                                  : Colors.grey[800],
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(8),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Tuần',
                              style: TextStyle(
                                color: !_showWorkoutTimeCard
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Conditionally show LogWorkoutTimeCard or TableCalendar
              _showWorkoutTimeCard
                  ? const LogWorkoutTimeCard()
                  : TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetailsPage(
                              selectedDate: selectedDay,
                              workouts: _workouts[selectedDay] ?? [],
                              onWorkoutAdded: (workout) =>
                                  _addWorkout(selectedDay, workout),
                            ),
                          ),
                        );
                      },
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(
                          color: Colors.white70,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF8854FF),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        outsideTextStyle: const TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.white54),
                        weekendStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  // Content for "Chuyên sâu" tab
  Widget _buildInDepthContent() {
    // Calculate BMI: weight (kg) / (height (m) * height (m))
    final double bmi = _weight / ((_height / 100) * (_height / 100));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'In-depth Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Detailed insights into your workout performance',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        // Body Metrics Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Body Metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              // Line Chart for Weight and 1RM
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                height: 200, // Adjust height as needed
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 10, // Adjust based on data range
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            );
                          },
                          interval: 10, // Adjust based on data range
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final week = value.toInt();
                            if (week >= 1 &&
                                week <= _bodyMetricsHistory.length) {
                              return Text(
                                'W$week',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    minX: 1,
                    maxX: _bodyMetricsHistory.length.toDouble(),
                    minY:
                        (_bodyMetricsHistory
                                    .map((e) => (e['weight'] as double))
                                    .reduce((a, b) => a < b ? a : b) -
                                5)
                            .floorToDouble(), // Adjust for padding
                    maxY:
                        (_bodyMetricsHistory
                                    .map((e) => (e['oneRepMax'] as double))
                                    .reduce((a, b) => a > b ? a : b) +
                                5)
                            .ceilToDouble(), // Adjust for padding
                    lineBarsData: [
                      // Weight Line
                      LineChartBarData(
                        spots: _bodyMetricsHistory
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                (entry.key + 1).toDouble(),
                                entry.value['weight'] as double,
                              ),
                            )
                            .toList(),
                        isCurved: true,
                        color: const Color(0xFF8854FF), // Purple for Weight
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF8854FF).withOpacity(0.2),
                        ),
                      ),
                      // 1RM Line
                      LineChartBarData(
                        spots: _bodyMetricsHistory
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                (entry.key + 1).toDouble(),
                                entry.value['oneRepMax'] as double,
                              ),
                            )
                            .toList(),
                        isCurved: true,
                        color: Colors.orange.shade400, // Orange for 1RM
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orange.shade400.withOpacity(0.2),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        // tooltipBgColor: Colors.grey[800],
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final week = spot.x.toInt();
                            final value = spot.y.toStringAsFixed(1);
                            final label = spot.barIndex == 0 ? 'Weight' : '1RM';
                            return LineTooltipItem(
                              '$label: $value kg\nWeek $week',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // const SizedBox(height: 6),
              // Legend for the chart
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Weight', const Color(0xFF8854FF)),
                  const SizedBox(width: 16),
                  _buildLegendItem('1RM', Colors.orange.shade400),
                ],
              ),
              const SizedBox(height: 12),
              // Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem(
                    'Weight',
                    '${_weight.toStringAsFixed(1)} kg',
                  ),
                  _buildMetricItem(
                    'Height',
                    '${_height.toStringAsFixed(1)} cm',
                  ),
                  _buildMetricItem('BMI', bmi.toStringAsFixed(1)),
                  _buildMetricItem(
                    'Body Fat',
                    '${_bodyFat.toStringAsFixed(1)}%',
                  ),
                  _buildMetricItem(
                    '1RM',
                    '${_oneRepMax.toStringAsFixed(1)} kg',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Update Metrics Button (migrated to design system)
              AppButton.primary(
                label: 'Update Metrics',
                onPressed: () => _showBodyMetricsUpdateModal(context),
                size: AppButtonSize.medium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Helper method to build metric item
  Widget _buildMetricItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
