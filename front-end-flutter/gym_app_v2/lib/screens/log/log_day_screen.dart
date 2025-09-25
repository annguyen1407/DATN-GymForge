import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../repositories/exercise_log_repository.dart';
import '../../services/api_constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/log_plan_card.dart';
import '../../widgets/plan_type_badge.dart';
import '../../widgets/pill_tab_bar.dart';
import 'log_workoutday_screen.dart';

class LogOfDayScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> workouts;
  final void Function(Map<String, dynamic>)? onWorkoutAdded;
  final double? weight;
  final double? height;
  final String? note;
  final List<Map<String, dynamic>>? rawWorkoutExerciseLogs;
  final String userId;

  const LogOfDayScreen({
    super.key,
    required this.selectedDate,
    required this.workouts,
    required this.userId,
    this.onWorkoutAdded,
    this.weight,
    this.height,
    this.note,
    this.rawWorkoutExerciseLogs,
  });

  @override
  State<LogOfDayScreen> createState() => _LogOfDayScreenState();
}

class _LogOfDayScreenState extends State<LogOfDayScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _bodyWeightController = TextEditingController();
  final _bodyHeightController = TextEditingController();
  final _foodNameController = TextEditingController();
  final _foodCaloriesController = TextEditingController();
  final _newNoteController = TextEditingController();
  bool _noteExpanded = false; // expand/collapse state for long note

  late TabController _tabController;
  late Map<String, dynamic> _bodyMetrics;
  late List<String> _notes;

  final _nutritionData = [
    {'meal': 'Breakfast', 'foods': <Map<String, dynamic>>[]},
    {'meal': 'Lunch', 'foods': <Map<String, dynamic>>[]},
  ];

  final _repo = ExerciseLogRepository(baseUrl: ApiConstants.baseUrl);
  bool _loadingSummary = false;
  String? _summaryError;
  List<Map<String, dynamic>>? _rawLogs;
  final List<Map<String, dynamic>> _planData = [];

  double _bmi(double w, double hCm) {
    final m = hCm / 100.0;
    if (m <= 0) return 0;
    return w / (m * m);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final w = widget.weight ?? 70.0;
    final h = widget.height ?? 170.0;
    _bodyMetrics = {'weight': w, 'height': h, 'bmi': _bmi(w, h)};
    _notes = [];
    if (widget.note != null && widget.note!.trim().isNotEmpty) {
      _notes.add(widget.note!.trim());
    }
    _rawLogs = widget.rawWorkoutExerciseLogs;
    _parsePlans();
    if (widget.rawWorkoutExerciseLogs == null ||
        widget.weight == null ||
        widget.height == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSummary());
    }
  }

  @override
  void didUpdateWidget(covariant LogOfDayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawWorkoutExerciseLogs != widget.rawWorkoutExerciseLogs) {
      _rawLogs = widget.rawWorkoutExerciseLogs;
      _planData.clear();
      _parsePlans();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bodyWeightController.dispose();
    _bodyHeightController.dispose();
    _foodNameController.dispose();
    _foodCaloriesController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final summary = await _repo.fetchDailySummary(
        userId: widget.userId,
        date: widget.selectedDate,
      );
      if (!mounted) return;
      if (summary != null) {
        if (widget.weight == null && summary.weight != null) {
          _bodyMetrics['weight'] = summary.weight!;
        }
        if (widget.height == null && summary.height != null) {
          _bodyMetrics['height'] = summary.height!;
        }
        _bodyMetrics['bmi'] = _bmi(
          _bodyMetrics['weight'],
          _bodyMetrics['height'],
        );
        if (summary.notes != null && summary.notes!.trim().isNotEmpty) {
          if (!_notes.contains(summary.notes!.trim())) {
            _notes.add(summary.notes!.trim());
          }
        }
        _rawLogs = summary.workoutExerciseLogsRaw;
        _planData.clear();
        _parsePlans();
      }
    } catch (e) {
      if (mounted) {
        _summaryError = e.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải nhật ký: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  void _parsePlans() {
    final raw = _rawLogs;
    if (raw == null || raw.isEmpty) return;
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final Map<String, Map<String, dynamic>> meta = {};
    for (final item in raw) {
      final workoutExercise = item['workoutExercise'] as Map<String, dynamic>?;
      final dayId = workoutExercise?['workoutDayId']?.toString() ?? 'unknown';
      grouped.putIfAbsent(dayId, () => []);
      final planObj = workoutExercise?['workoutPlan'] as Map<String, dynamic>?;
      meta.putIfAbsent(
        dayId,
        () => {
          'planName':
              planObj?['name'] ?? workoutExercise?['planName'] ?? 'Kế hoạch',
          'planType': planObj?['planType'] ?? planObj?['type'],
          'dayNumber':
              workoutExercise?['dayNumber'] ?? workoutExercise?['day_number'],
        },
      );
      final prog = () {
        final v = item['progressPercent'];
        if (v is num) return (v.toDouble() / 100).clamp(0.0, 1.0);
        return 0.0;
      }();
      grouped[dayId]!.add({
        'id': item['id'],
        'name': item['exerciseName'] ?? item['name'] ?? 'Bài tập',
        'progress': prog,
        'description': '',
      });
    }
    grouped.forEach((dayId, exercises) {
      final m = meta[dayId] ?? {};
      final avg = exercises.isEmpty
          ? 0.0
          : exercises
                    .map((e) => (e['progress'] as double))
                    .fold(0.0, (p, v) => p + v) /
                exercises.length;
      _planData.add({
        'workoutDayId': dayId,
        'name': m['planName'],
        'planType': m['planType'],
        'dayNumber': m['dayNumber'],
        'progress': avg,
        'exercises': exercises,
      });
    });
  }

  Color _planTypeColor(String? raw) =>
      PlanTypeBadge.baseColor(raw?.toString().toUpperCase());

  Widget _dayBadge(dynamic dnRaw) {
    int? dn;
    if (dnRaw is int)
      dn = dnRaw;
    else if (dnRaw is String)
      dn = int.tryParse(dnRaw);
    if (dn == null) return const SizedBox.shrink();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8854FF), width: 1),
      ),
      alignment: Alignment.center,
      child: const Text('D', style: TextStyle(color: Colors.white)),
      // Replacing with simple badge; could restore number if needed
    );
  }

  Widget _banner() {
    if (_loadingSummary) {
      return const LinearProgressIndicator(
        minHeight: 2,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation(Color(0xFF8854FF)),
      );
    }
    if (_summaryError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        color: Colors.redAccent.withOpacity(.15),
        child: Text(
          'Lỗi: $_summaryError',
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  InputDecoration _inputDec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white54),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF8854FF)),
    ),
  );

  // Compact notes area with expandable long text
  Widget _buildNotesArea() {
    final hasNote = _notes.isNotEmpty && _notes.first.trim().isNotEmpty;
    final noteText = hasNote ? _notes.first : 'Chưa có ghi chú cho ngày này';
    final textStyle = TextStyle(
      color: hasNote ? Colors.white : Colors.white54,
      fontSize: 14,
      height: 1.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLong =
            hasNote &&
            _isLongNote(noteText, textStyle, constraints.maxWidth, 5);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                child: Text(
                  noteText,
                  style: textStyle,
                  maxLines: !_noteExpanded && isLong ? 5 : null,
                  overflow: !_noteExpanded && isLong
                      ? TextOverflow.fade
                      : TextOverflow.visible,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isLong)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _noteExpanded = !_noteExpanded),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _noteExpanded ? 'Thu gọn' : 'Xem thêm',
                          style: const TextStyle(
                            color: Color(0xFF8854FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 24),
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Color(0xFF8854FF),
                      size: 22,
                    ),
                    tooltip: 'Chỉnh sửa ghi chú',
                    onPressed: _showEditNoteModal,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isLongNote(
    String text,
    TextStyle style,
    double maxWidth,
    int maxLines,
  ) {
    if (text.isEmpty) return false;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    );
    tp.layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }

  Future<void> _showEditNoteModal() async {
    // Pre-fill with existing first note (or empty)
    _newNoteController.text = _notes.isNotEmpty ? _notes.first : '';
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chỉnh sửa ghi chú',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newNoteController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Nhập ghi chú...'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton.text(
                    label: 'Hủy',
                    onPressed: () => Navigator.pop(ctx),
                    size: AppButtonSize.small,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.primary(
                    label: 'Lưu',
                    size: AppButtonSize.small,
                    onPressed: () {
                      final text = _newNoteController.text.trim();
                      setState(() {
                        if (_notes.isEmpty) {
                          if (text.isNotEmpty) _notes.add(text);
                        } else {
                          if (text.isNotEmpty) {
                            _notes[0] = text;
                          } else {
                            // If cleared, remove note
                            _notes.clear();
                          }
                        }
                      });
                      Navigator.pop(ctx);
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

  Future<void> _showEditBodyMetrics() async {
    _bodyWeightController.text = _bodyMetrics['weight'].toStringAsFixed(1);
    _bodyHeightController.text = _bodyMetrics['height'].toStringAsFixed(1);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chỉnh sửa chỉ số',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyWeightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Weight (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyHeightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Height (cm)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton.text(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(ctx),
                    size: AppButtonSize.small,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.primary(
                    label: 'Save',
                    size: AppButtonSize.small,
                    onPressed: () {
                      final w = double.tryParse(_bodyWeightController.text);
                      final h = double.tryParse(_bodyHeightController.text);
                      if (w != null && h != null && w > 0 && h > 0) {
                        setState(() {
                          _bodyMetrics['weight'] = w;
                          _bodyMetrics['height'] = h;
                          _bodyMetrics['bmi'] = _bmi(w, h);
                        });
                        Navigator.pop(ctx);
                      }
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

  Future<void> _showAddFood(Map<String, dynamic> meal) async {
    _foodNameController.clear();
    _foodCaloriesController.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Food to ${meal['meal']}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _foodNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Food Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _foodCaloriesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Calories (kcal)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton.text(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(ctx),
                    size: AppButtonSize.small,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.primary(
                    label: 'Save',
                    size: AppButtonSize.small,
                    onPressed: () {
                      final name = _foodNameController.text.trim();
                      final cal = double.tryParse(_foodCaloriesController.text);
                      if (name.isNotEmpty && cal != null && cal > 0) {
                        setState(
                          () => (meal['foods'] as List).add({
                            'name': name,
                            'calories': cal.toInt(),
                          }),
                        );
                        Navigator.pop(ctx);
                      }
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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _metric(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final caloriesIntake = _nutritionData.fold<int>(
      0,
      (s, meal) =>
          s +
          (meal['foods'] as List<Map<String, dynamic>>).fold<int>(
            0,
            (ss, f) => ss + (f['calories'] as int),
          ),
    );
    final caloriesBurned = widget.workouts.fold<int>(
      0,
      (s, w) =>
          s +
          (((w['sets'] ?? 0) as int) *
                  ((w['reps'] ?? 0) as int) *
                  ((w['weight'] ?? 0.0) as double) *
                  0.1)
              .toInt(),
    );
    final ratio = caloriesIntake > 0
        ? (caloriesBurned / caloriesIntake).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _formatDate(widget.selectedDate),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PillTabBar(
          controller: _tabController,
          labels: const ['Ghi chú', 'Kế hoạch', 'Cơ thể', 'Dinh dưỡng'],
        ),
      ),
      body: Column(
        children: [
          _banner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Notes Tab (Vietnamese UI - single column, edit only)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ghi chú',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNotesArea(),
                    ],
                  ),
                ),
                // Plans Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _planData.isEmpty
                      ? const Center(
                          child: Text(
                            'No plans available',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _planData.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final plan = _planData[i];
                            final type = plan['planType']?.toString();
                            return PlanCard(
                              plan: plan,
                              planTypeColor: _planTypeColor(type),
                              dayBadge: _dayBadge(plan['dayNumber']),
                              planTypeChip: type == null
                                  ? const SizedBox.shrink()
                                  : PlanTypeBadge(
                                      planType: type.toUpperCase(),
                                      dense: true,
                                      fontSize: 11,
                                    ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutLogScreen(
                                    planName: plan['name'],
                                    exercises: List<Map<String, dynamic>>.from(
                                      plan['exercises'],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Body Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chỉ số cơ thể',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFF8854FF),
                              size: 20,
                            ),
                            onPressed: _showEditBodyMetrics,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _metric(
                            'Weight',
                            '${_bodyMetrics['weight'].toStringAsFixed(1)} kg',
                          ),
                          _metric(
                            'Height',
                            '${_bodyMetrics['height'].toStringAsFixed(1)} cm',
                          ),
                          _metric(
                            'BMI',
                            '${_bodyMetrics['bmi'].toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nutrition Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      _nutritionData.every((m) => (m['foods'] as List).isEmpty)
                      ? const Center(
                          child: Text(
                            'No nutrition data recorded for this date',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Calories Summary',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Intake 🍗 : $caloriesIntake kcal',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Burned 🔥: $caloriesBurned kcal',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    CircularPercentIndicator(
                                      radius: 50,
                                      lineWidth: 8,
                                      percent: ratio,
                                      center: Text(
                                        '${(ratio * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      progressColor: const Color(0xFF8854FF),
                                      backgroundColor: Colors.grey[800]!,
                                      circularStrokeCap:
                                          CircularStrokeCap.round,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._nutritionData.map((meal) {
                                final foods =
                                    meal['foods'] as List<Map<String, dynamic>>;
                                final total = foods.fold<int>(
                                  0,
                                  (s, f) => s + (f['calories'] as int),
                                );
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            meal['meal'] as String? ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              color: Color(0xFF8854FF),
                                              size: 20,
                                            ),
                                            onPressed: () => _showAddFood(meal),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (foods.isEmpty)
                                        const Text(
                                          'No foods added yet',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        )
                                      else
                                        ...foods.asMap().entries.map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        e.value['name'],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${e.value['calories']} kcal',
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  onPressed: () => setState(
                                                    () => foods.removeAt(e.key),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      const Divider(color: Colors.grey),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Items: ${foods.length}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Total: $total kcal',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
