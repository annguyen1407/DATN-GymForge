import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/log_tab.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/log_workout_time_card.dart';
import '../../widgets/workout_time_chart.dart';
import '../../widgets/workout_details_page.dart';

/// LogScreen: Tab "Log" hiển thị lịch sử tập luyện, thống kê, các nhóm workout đã hoàn thành
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  // State variable to track the selected tab
  String _selectedTab = 'Lịch sử';

  // State variables for body metrics (placeholder values)
  double _weight = 70.0; // kg
  double _height = 175.0; // cm
  double _bodyFat = 20.0; // percentage
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

  // Function to handle tab selection
  void _onTabSelected(String tab) {
    setState(() {
      _selectedTab = tab;
    });
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Validate and update weight
                      final weightInput = weightController.text;
                      final newWeight = double.tryParse(weightInput);
                      if (newWeight != null && newWeight > 0) {
                        setState(() {
                          _weight = newWeight;
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
                        });
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8854FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs chuyển giữa lịch sử và chuyên sâu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LogTab(
                    label: 'Lịch sử',
                    selected: _selectedTab == 'Lịch sử',
                    onTap: () => _onTabSelected('Lịch sử'),
                  ),
                  const SizedBox(width: 32),
                  LogTab(
                    label: 'Chuyên sâu',
                    selected: _selectedTab == 'Chuyên sâu',
                    onTap: () => _onTabSelected('Chuyên sâu'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Conditional content based on selected tab
              _selectedTab == 'Lịch sử'
                  ? _buildHistoryContent()
                  : _buildInDepthContent(),
            ],
          ),
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
                'Workout History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'View your workout time or select a date for details',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Toggle Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleButton('Workout Time', _showWorkoutTimeCard, () => _toggleHistoryView(true)),
                  const SizedBox(width: 16),
                  _buildToggleButton('Calendar', !_showWorkoutTimeCard, () => _toggleHistoryView(false)),
                ],
              ),
              const SizedBox(height: 16),
              // Conditionally show LogWorkoutTimeCard or TableCalendar
              _showWorkoutTimeCard
                  ? const LogWorkoutTimeCard()
                  : TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                              onWorkoutAdded: (workout) => _addWorkout(selectedDay, workout),
                            ),
                          ),
                        );
                      },
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(color: Colors.white70),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF8854FF),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        outsideTextStyle: const TextStyle(color: Colors.white54),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
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

  // Helper method to build toggle button
  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF8854FF) : Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
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
              // Update Metrics Button
              ElevatedButton(
                onPressed: () => _showBodyMetricsUpdateModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8854FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(double.infinity, 0), // Full width
                ),
                child: const Text(
                  'Update Metrics',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem('Weight', '${_weight.toStringAsFixed(1)} kg'),
                  _buildMetricItem('Height', '${_height.toStringAsFixed(1)} cm'),
                  _buildMetricItem('BMI', bmi.toStringAsFixed(1)),
                  _buildMetricItem('Body Fat', '${_bodyFat.toStringAsFixed(1)}%'),
                  _buildMetricItem('1RM', '${_oneRepMax.toStringAsFixed(1)} kg'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Workout Time Chart
        const WorkoutTimeChart(),
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
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

