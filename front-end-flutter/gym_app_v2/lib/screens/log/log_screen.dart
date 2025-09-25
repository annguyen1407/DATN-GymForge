// Clean rebuilt LogScreen after corruption cleanup.
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/extensions/color_extensions.dart';
import '../../widgets/app_button.dart';
import '../../widgets/today_stat.dart';
import '../../widgets/skeleton/today_stat_skeleton.dart';
import '../../repositories/exercise_log_repository.dart';
import '../../services/api_constants.dart';
import '../../core/auth/token_manager.dart';
import '../../services/log_out_service.dart';
import '../../core/auth/session_guard.dart';
import '../../widgets/log_workout_time_card.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/segmented_pill_switch.dart';
import 'log_day_screen.dart';
import '../../widgets/animations/animated_appear.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double? _weight;
  double? _height;
  double? _bodyFat;
  double? _oneRepMax;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showWorkoutTimeCard = true;
  static const double _historySwitchContentHeight =
      420; // fixed to prevent jump

  DailyExerciseLogSummary? _dailySummary;
  bool _loadingSummary = false;
  String? _summaryError;
  final _repo = ExerciseLogRepository(baseUrl: ApiConstants.baseUrl);
  String? _userId;
  String?
  _accessToken; // still retrieved but repository no longer needs explicit token
  bool _authResolving = true;

  final Map<DateTime, List<Map<String, dynamic>>> _workouts = {};
  final List<Map<String, dynamic>> _bodyMetricsHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initAuthAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleHistoryView(bool show) =>
      setState(() => _showWorkoutTimeCard = show);

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
    if (_accessToken == null || _userId == null) return;
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final res = await _repo.fetchDailySummary(userId: _userId!, date: date);
      setState(() {
        _dailySummary = res;
        if (res != null) {
          if (res.weight != null) _weight = res.weight;
          if (res.height != null && res.height! > 0) _height = res.height;
        }
      });
    } catch (e) {
      setState(() => _summaryError = e.toString());
      // Trường hợp repo ném lỗi chứa 401 cũ -> sử dụng guard để quyết định
      if (e.toString().contains('401')) {
        final decision = await SessionGuard.handlePersistent401(
          context: context,
          source: 'dailySummary',
        );
        if (decision == UnauthorizedResolution.logout) {
          return; // đã logout
        }
        // softFail: giữ nguyên lỗi cho UI hiển thị
      }
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  void _addWorkout(DateTime date, Map<String, dynamic> workout) {
    setState(() => (_workouts[date] ??= []).add(workout));
  }

  Future<void> _showBodyMetricsUpdateModal(BuildContext context) async {
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final oneRepMaxController = TextEditingController();
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
              decoration: _metricInputDecoration('Weight (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _metricInputDecoration('Height (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: oneRepMaxController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _metricInputDecoration('One-Rep Max (kg)'),
            ),
            const SizedBox(height: 16),
            Row(
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
                      final w = double.tryParse(weightController.text);
                      if (w != null && w > 0) {
                        setState(() {
                          _weight = w;
                          _bodyMetricsHistory.add({
                            'week': _bodyMetricsHistory.length + 1,
                            'date': DateTime.now(),
                            'weight': w,
                            'oneRepMax': _oneRepMax,
                          });
                        });
                      }
                      final h = double.tryParse(heightController.text);
                      if (h != null && h > 0) {
                        setState(() => _height = h);
                      }
                      final r = double.tryParse(oneRepMaxController.text);
                      if (r != null && r > 0) {
                        setState(() {
                          _oneRepMax = r;
                          if (_bodyMetricsHistory.isNotEmpty) {
                            _bodyMetricsHistory.last['oneRepMax'] = r;
                          }
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

  InputDecoration _metricInputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54),
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white54),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF8854FF)),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            PillTabBar(
              controller: _tabController,
              labels: const ['Lịch sử', 'Chuyên sâu'],
              horizontalPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              height: kTextTabBarHeight + 10,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              indicatorOpacity: 0.22,
              borderRadius: 12,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _KeepAliveWrapper(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: _buildHistoryContent(),
                    ),
                  ),
                  _KeepAliveWrapper(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: _buildInDepthContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Tổng quan hôm nay'),
        const SizedBox(height: 12),
        AnimatedAppear(child: _buildTodayStatSection()),
        const SizedBox(height: 24),
        // (Đã bỏ cụm icon danh mục bài tập để giảm nhiễu giao diện)
        const SizedBox(height: 8),
        const Text(
          'Thống kê & thông tin chi tiết',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 180,
                  child: SegmentedPillSwitch(
                    labels: const ['Ngày', 'Tháng'],
                    selectedIndex: _showWorkoutTimeCard ? 0 : 1,
                    onChanged: (i) => _toggleHistoryView(i == 0),
                    height: 38,
                    borderRadius: 14,
                    activeColor: const Color(0xFF8854FF),
                    backgroundColor: const Color(0xFF202022),
                    activeTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    inactiveTextStyle: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _historySwitchContentHeight,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final isCalendar = child.key == const ValueKey('calendar');
                    final offsetTween = Tween<Offset>(
                      begin: Offset(isCalendar ? 0.18 : -0.18, 0),
                      end: Offset.zero,
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offsetTween.animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _showWorkoutTimeCard
                      ? SizedBox(
                          key: const ValueKey('dayCard'),
                          height: _historySwitchContentHeight,
                          child: LogWorkoutTimeCard(
                            userId: _userId,
                            token: _accessToken,
                          ),
                        )
                      : SizedBox(
                          key: const ValueKey('calendar'),
                          height: _historySwitchContentHeight,
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) async {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _loadingSummary = true;
                              });
                              try {
                                await _fetchDailySummary(selectedDay);
                              } catch (_) {}
                              final summary = _dailySummary;
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LogOfDayScreen(
                                    selectedDate: selectedDay,
                                    workouts: _workouts[selectedDay] ?? [],
                                    onWorkoutAdded: (w) =>
                                        _addWorkout(selectedDay, w),
                                    weight: summary?.weight,
                                    height: summary?.height,
                                    note: summary?.notes,
                                    rawWorkoutExerciseLogs:
                                        summary?.workoutExerciseLogsRaw,
                                  ),
                                ),
                              );
                            },
                            calendarStyle: CalendarStyle(
                              defaultTextStyle: const TextStyle(
                                color: Colors.white,
                              ),
                              weekendTextStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: Color(0xFF8854FF),
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: Colors.white.withOpacityRatio(0.3),
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
                        ),
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
      return const TodayStatSkeleton(compact: true);
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
              await LogoutService.logout(
                context,
                reason: 'manual_relogin_button',
              );
            },
          ),
        ],
      );
    }
    if (_loadingSummary) {
      return const TodayStatSkeleton(compact: true);
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
        circleLabel: 'Buổi tập',
        compact: true,
      );
    }
    // Hiển thị số buổi tập (workout day distinct) thay vì tổng lượt (sessions)
    return TodayStat(
      workoutSets: s.uniqueSessions,
      exercisesCount: s.totalExercises,
      calories: s.caloriesBurned,
      caloriesIntake: s.caloriesIntake,
      points: null,
      workoutTimeMinutes: s.totalWorkoutTimeMinutes,
      circleLabel: 'Buổi tập',
      compact: true,
    );
  }

  Widget _buildInDepthContent() {
    final double? bmi = (_weight != null && _height != null && _height! > 0)
        ? _weight! / ((_height! / 100) * (_height! / 100))
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phân tích chuyên sâu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
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
              const Text(
                'Chỉ số cơ thể',
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
                    'Chưa có chỉ số',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                )
              else ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [],
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
                  'Chưa có ghi nhận',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              const SizedBox(height: 16),
              AppButton.primary(
                label: 'Cập nhật chỉ số',
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        letterSpacing: .2,
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
