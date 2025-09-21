import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/today_stat.dart';
import '../../repositories/exercise_log_repository.dart';
import '../../core/auth/token_manager.dart';
import '../../services/log_out_service.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/log_workout_time_card.dart';
import 'log_day_screen.dart'; // renamed class inside to LogOfDayScreen

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

  // State variables for body metrics (initially empty – will be populated from future API)
  double? _weight; // kg
  double? _height; // cm
  double? _bodyFat; // percentage
  double? _oneRepMax; // kg

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // State for toggling between LogWorkoutTimeCard and TableCalendar
  bool _showWorkoutTimeCard = true;

  // Daily summary + auth state
  DailyExerciseLogSummary? _dailySummary;
  bool _loadingSummary = false;
  String? _summaryError;
  final _repo = ExerciseLogRepository(baseUrl: 'http://localhost:3000');
  String? _userId;
  String? _accessToken;
  bool _authResolving = true; // while resolving token & user id

  // Workout data per day (start empty, to be filled via future API integration or user input)
  final Map<DateTime, List<Map<String, dynamic>>> _workouts = {};

  // Historical body metrics (empty until fetched)
  final List<Map<String, dynamic>> _bodyMetricsHistory = [];

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

    _initAuthAndLoad();
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

  Future<void> _initAuthAndLoad() async {
    try {
      final tm = TokenManager.instance;
      final token = await tm.getValidAccessToken();
      final uid = await tm.getCurrentUserId();
      if (!mounted) return;
      if (token == null || uid == null) {
        setState(() {
          _authResolving = false;
          _summaryError = 'Chưa đăng nhập hoặc token hết hạn';
        });
        return;
      }
      setState(() {
        _accessToken = token;
        _userId = uid;
        _authResolving = false;
      });
      await _fetchDailySummary(DateTime.now());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authResolving = false;
        _summaryError = 'Lỗi khởi tạo auth: $e';
      });
    }
  }

  Future<void> _fetchDailySummary(DateTime date) async {
    if (_accessToken == null || _userId == null) {
      // If auth not ready, skip
      return;
    }
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final res = await _repo.fetchDailySummary(
        userId: _userId!,
        date: date,
        token: _accessToken!,
      );
      setState(() {
        _dailySummary = res;
      });
    } catch (e) {
      setState(() {
        _summaryError = e.toString();
      });
      // If unauthorized surfaced (status 401), attempt logout to force re-auth
      final msg = e.toString();
      if (msg.contains('401') && mounted) {
        await LogoutService.logout(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSummary = false;
        });
      }
    }
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
        _buildTodayStatSection(),
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
                              'Tháng',
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
                        // Refetch summary for chosen date
                        _fetchDailySummary(selectedDay);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LogOfDayScreen(
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

  Widget _buildTodayStatSection() {
    if (_authResolving) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }
    if (_accessToken == null || _userId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn cần đăng nhập để xem thống kê',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          AppButton.primary(
            label: 'Đăng nhập lại',
            size: AppButtonSize.small,
            onPressed: () async {
              await LogoutService.logout(context);
            },
          ),
        ],
      );
    }
    if (_loadingSummary) {
      return const Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }
    if (_summaryError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Load error: $_summaryError',
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
          const SizedBox(height: 8),
          AppButton.outline(
            label: 'Retry',
            onPressed: () => _fetchDailySummary(_selectedDay ?? DateTime.now()),
          ),
        ],
      );
    }
    final s = _dailySummary;
    if (s == null) {
      return const TodayStat(
        workoutSets: 0,
        exercisesCount: 0,
        calories: 0,
        caloriesIntake: 0,
        circleLabel: 'Sessions',
        compact: true,
      );
    }
    return TodayStat(
      workoutSets: s.sessions,
      exercisesCount: s.totalExercises,
      calories: s.caloriesBurned,
      caloriesIntake: s.caloriesIntake,
      points: null,
      circleLabel: 'Sessions',
      compact: true,
    );
  }

  // Content for "Chuyên sâu" tab
  Widget _buildInDepthContent() {
    // Calculate BMI: weight (kg) / (height (m) * height (m))
    final double? bmi = (_weight != null && _height != null && _height! > 0)
        ? _weight! / ((_height! / 100) * (_height! / 100))
        : null;

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
        // Body Metrics Card (guard for empty state)
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
              if (_bodyMetricsHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: const Text(
                    'No body metrics yet',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                )
              else ...[
                // (Chart removed when we remove mock data; reintroduce when backend available)
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    // Legend placeholders if re-enabled later
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (_weight != null ||
                  _height != null ||
                  _bodyFat != null ||
                  _oneRepMax != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_weight != null)
                      _buildMetricItem(
                        'Weight',
                        '${_weight!.toStringAsFixed(1)} kg',
                      ),
                    if (_height != null)
                      _buildMetricItem(
                        'Height',
                        '${_height!.toStringAsFixed(1)} cm',
                      ),
                    if (bmi != null)
                      _buildMetricItem('BMI', bmi.toStringAsFixed(1)),
                    if (_bodyFat != null)
                      _buildMetricItem(
                        'Body Fat',
                        '${_bodyFat!.toStringAsFixed(1)}%',
                      ),
                    if (_oneRepMax != null)
                      _buildMetricItem(
                        '1RM',
                        '${_oneRepMax!.toStringAsFixed(1)} kg',
                      ),
                  ],
                )
              else
                const Text(
                  'No metrics recorded',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
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
}
