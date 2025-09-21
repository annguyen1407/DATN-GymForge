import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'log_workoutday_screen.dart'; // contains WorkoutLogScreen
import '../../widgets/log_plan_card.dart';
import '../../widgets/pill_tab_bar.dart';

/// LogOfDayScreen: Displays detailed workout information for a selected date with tabs
class LogOfDayScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> workouts; // existing workouts list
  final void Function(Map<String, dynamic>)? onWorkoutAdded;
  final double? weight;
  final double? height;
  final String? note;
  final List<Map<String, dynamic>>?
  rawWorkoutExerciseLogs; // passed from daily summary for plan tab parsing

  const LogOfDayScreen({
    super.key,
    required this.selectedDate,
    required this.workouts,
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
  // Controllers & state referenced in bottom sheets (keep minimal subset to satisfy existing usages)
  final TextEditingController _bodyWeightController = TextEditingController();
  final TextEditingController _bodyHeightController = TextEditingController();
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _foodCaloriesController = TextEditingController();
  final TextEditingController _newNoteController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  late Map<String, dynamic> _bodyMetrics;

  late List<String> _notes;
  final List<Map<String, dynamic>> _nutritionData = [
    {'meal': 'Breakfast', 'foods': <Map<String, dynamic>>[]},
    {'meal': 'Lunch', 'foods': <Map<String, dynamic>>[]},
  ];

  double _calculateBMI(double weight, double heightCm) {
    final m = heightCm / 100.0;
    if (m <= 0) return 0;
    return weight / (m * m);
  }

  // UI state for tabs / plans (restored minimal fields)
  late TabController _tabController;
  final List<Map<String, dynamic>> _planData =
      []; // legacy placeholder structure for UI (will be filled from parsed groups)
  // (Optional) store parsed groups later if needed

  @override
  void initState() {
    super.initState();
    // Fix: TabController length must match number of tabs (4) and use proper vsync
    _tabController = TabController(length: 4, vsync: this);
    final w = widget.weight ?? 70.0;
    final h = widget.height ?? 175.0;
    _bodyMetrics = {'weight': w, 'height': h, 'bmi': _calculateBMI(w, h)};
    _notes = [];
    if (widget.note != null && widget.note!.trim().isNotEmpty) {
      _notes.add(widget.note!.trim());
    }
    _buildPlanDataFromRawLogs();
  }

  @override
  void didUpdateWidget(covariant LogOfDayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawWorkoutExerciseLogs != widget.rawWorkoutExerciseLogs) {
      _planData.clear();
      _buildPlanDataFromRawLogs();
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
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _buildPlanDataFromRawLogs() {
    final raw = widget.rawWorkoutExerciseLogs;
    if (raw == null || raw.isEmpty) return;
    try {
      // Use repository parser (import extension) – replicate lightweight logic here to avoid tight coupling.
      // Since we can't import repository directly without circular concerns, re-implement minimal grouping inline.
      final Map<String, List<Map<String, dynamic>>> bucket = {};
      final Map<String, Map<String, dynamic>> meta = {};
      for (final item in raw) {
        final workoutExercise =
            item['workoutExercise'] as Map<String, dynamic>?;
        final dayId = workoutExercise?['workoutDayId']?.toString() ?? 'unknown';
        final int? dayNumber = () {
          final candidates = [
            item['dayNumber'],
            workoutExercise?['dayNumber'],
            workoutExercise?['day_number'],
            workoutExercise?['DayNumber'],
          ];
          for (final c in candidates) {
            if (c is num) return c.toInt();
            if (c is String) {
              final parsed = int.tryParse(c);
              if (parsed != null) return parsed;
            }
          }
          return null;
        }();
        final planObj =
            workoutExercise?['workoutPlan'] as Map<String, dynamic>?;
        final planName =
            planObj?['name']?.toString() ??
            workoutExercise?['planName']?.toString() ??
            'Kế hoạch';
        final planType =
            planObj?['planType']?.toString() ?? planObj?['type']?.toString();
        final progressPercent = () {
          final v = item['progressPercent'];
          if (v is num) return v.toDouble();
          return 0.0;
        }();
        bucket.putIfAbsent(dayId, () => []);
        bucket[dayId]!.add({
          'id': item['id'],
          'name': item['exerciseName'] ?? item['name'] ?? 'Bài tập',
          'progress': (progressPercent / 100).clamp(
            0.0,
            1.0,
          ), // normalize 0..1 for UI
          'description': '',
        });
        meta.putIfAbsent(
          dayId,
          () => {
            'planName': planName,
            'planType': planType,
            'dayNumber': dayNumber,
          },
        );
      }
      bucket.forEach((dayId, exercises) {
        final m = meta[dayId] ?? {};
        final avgProgress = exercises.isEmpty
            ? 0.0
            : exercises
                      .map((e) => (e['progress'] as double))
                      .fold(0.0, (p, v) => p + v) /
                  exercises.length;
        // debug print removed after validation
        _planData.add({
          'workoutDayId': dayId,
          'name': (m['planName'] ?? 'Kế hoạch').toString(),
          'planType': m['planType'],
          'dayNumber': m['dayNumber'],
          'progress': avgProgress, // 0..1 for UI
          'exercises': exercises,
        });
      });
    } catch (_) {
      // swallow errors, keep empty plan data
    }
  }

  Color _planTypeColor(String? type) {
    if (type == null) return const Color(0xFF8854FF);
    switch (type.toLowerCase()) {
      case 'strength':
      case 'power':
        return Colors.redAccent;
      case 'hypertrophy':
        return Colors.orangeAccent;
      case 'endurance':
      case 'cardio':
        return Colors.lightBlueAccent;
      case 'flexibility':
      case 'mobility':
        return Colors.tealAccent;
      case 'weight_loss':
        return Colors.pinkAccent;
      default:
        return const Color(0xFF8854FF);
    }
  }

  // Removed _buildPlanTitle (inlined usage within _PlanCard)

  Widget _buildPlanTypeChip(dynamic planTypeRaw) {
    final t = planTypeRaw?.toString();
    if (t == null || t.isEmpty) {
      return const SizedBox.shrink();
    }
    final color = _planTypeColor(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDayNumberBadge(dynamic dayNumberRaw) {
    int? dn;
    if (dayNumberRaw is int) dn = dayNumberRaw;
    if (dayNumberRaw is String) dn = int.tryParse(dayNumberRaw);
    if (dn == null) return const SizedBox.shrink();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8854FF), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        'D$dn',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // Function to show modal for adjusting body metrics
  Future<void> _showAdjustBodyMetricsModal(BuildContext context) async {
    _bodyWeightController.text = _bodyMetrics['weight'].toStringAsFixed(1);
    _bodyHeightController.text = _bodyMetrics['height'].toStringAsFixed(1);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust Body Metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyWeightController,
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
              const SizedBox(height: 16),
              TextField(
                controller: _bodyHeightController,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppButton.text(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
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
                        final weight = double.tryParse(
                          _bodyWeightController.text,
                        );
                        final height = double.tryParse(
                          _bodyHeightController.text,
                        );
                        if (weight != null &&
                            weight > 0 &&
                            height != null &&
                            height > 0) {
                          setState(() {
                            _bodyMetrics['weight'] = weight;
                            _bodyMetrics['height'] = height;
                            _bodyMetrics['bmi'] = _calculateBMI(weight, height);
                          });
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show modal for adding a food to a meal
  Future<void> _showAddFoodModal(
    BuildContext context,
    Map<String, dynamic> meal,
  ) async {
    _foodNameController.clear();
    _foodCaloriesController.clear();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              TextField(
                controller: _foodNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Food Name',
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
              TextField(
                controller: _foodCaloriesController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Calories (kcal)',
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
                        final foodName = _foodNameController.text.trim();
                        final foodCalories = double.tryParse(
                          _foodCaloriesController.text,
                        );
                        if (foodName.isNotEmpty &&
                            foodCalories != null &&
                            foodCalories > 0) {
                          setState(() {
                            (meal['foods'] as List).add({
                              'name': foodName,
                              'calories': foodCalories.toInt(),
                            });
                          });
                          _foodNameController.clear();
                          _foodCaloriesController.clear();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show modal for adding a new note
  Future<void> _showAddNoteModal(BuildContext context) async {
    _newNoteController.clear();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Note',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newNoteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Enter Note',
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
                        final note = _newNoteController.text.trim();
                        if (note.isNotEmpty) {
                          setState(() {
                            _notes.add(note);
                          });
                          _newNoteController.clear();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate calories intake from all foods across meals
    final caloriesIntake = _nutritionData.fold<int>(
      0,
      (sum, meal) =>
          sum +
          (meal['foods'] as List<Map<String, dynamic>>).fold<int>(
            0,
            (mealSum, food) => mealSum + (food['calories'] as int),
          ),
    );
    final caloriesBurned = widget.workouts.isNotEmpty
        ? widget.workouts.fold<int>(
            0,
            (sum, workout) =>
                sum +
                ((workout['sets'] as int) *
                        (workout['reps'] as int) *
                        (workout['weight'] as double) *
                        0.1)
                    .toInt(),
          )
        : 500; // Mock value if no workouts
    final calorieRatio = caloriesIntake > 0
        ? (caloriesBurned / caloriesIntake).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Show only the date as requested
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
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Ghi chú (Notes) Tab
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
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
                        onPressed: () => _showAddNoteModal(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _notes.isEmpty
                      ? const Center(
                          child: Text(
                            'No additional notes added',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _notes.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: BoxConstraints(minHeight: 80),
                              child: Stack(
                                children: [
                                  Text(
                                    note,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.more_horiz,
                                        color: Color(0xFF8854FF),
                                        size: 25,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _notes.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            // Kế hoạch (Plan) Tab
            SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _planData.isEmpty
                    ? const Center(
                        child: Text(
                          'No plans available',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _planData.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final plan = _planData[index];
                          return PlanCard(
                            plan: plan,
                            planTypeColor: _planTypeColor(
                              plan['planType']?.toString(),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WorkoutLogScreen(
                                    planName: plan['name'],
                                    exercises: List<Map<String, dynamic>>.from(
                                      plan['exercises'],
                                    ),
                                  ),
                                ),
                              );
                            },
                            dayBadge: _buildDayNumberBadge(plan['dayNumber']),
                            planTypeChip: _buildPlanTypeChip(plan['planType']),
                          );
                        },
                      ),
              ),
            ),
            // Cơ thể (Body) Tab
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
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
                          onPressed: () => _showAdjustBodyMetricsModal(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricItem(
                          'Weight',
                          '${_bodyMetrics['weight'].toStringAsFixed(1)} kg',
                        ),
                        _buildMetricItem(
                          'Height',
                          '${_bodyMetrics['height'].toStringAsFixed(1)} cm',
                        ),
                        _buildMetricItem(
                          'BMI',
                          '${_bodyMetrics['bmi'].toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Dinh dưỡng (Nutrition) Tab
            Padding(
              padding: const EdgeInsets.all(16),
              child: _nutritionData.isEmpty
                  ? const Center(
                      child: Text(
                        'No nutrition data recorded for this date',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  radius: 60.0,
                                  lineWidth: 10.0,
                                  percent: calorieRatio,
                                  center: Text(
                                    '${(calorieRatio * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  progressColor: const Color(0xFF8854FF),
                                  backgroundColor: Colors.grey[800]!,
                                  circularStrokeCap: CircularStrokeCap.round,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _nutritionData.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final meal = _nutritionData[index];
                              final foods =
                                  meal['foods'] as List<Map<String, dynamic>>;
                              final totalCalories = foods.fold<int>(
                                0,
                                (sum, food) => sum + (food['calories'] as int),
                              );
                              return Container(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  3,
                                  12,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          meal['meal'],
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
                                          onPressed: () =>
                                              _showAddFoodModal(context, meal),
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
                                      ...foods.asMap().entries.map((entry) {
                                        final foodIndex = entry.key;
                                        final food = entry.value;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[800],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Stack(
                                              children: [
                                                Row(
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
                                                            food['name'],
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          Text(
                                                            '${food['calories']} kcal',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white54,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        foods.removeAt(
                                                          foodIndex,
                                                        );
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    const Divider(color: Colors.grey),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Meals: ${foods.length}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Total: $totalCalories kcal',
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
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
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

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  // Function to show modal for adding a new workout
}

/// Reusable styled plan card widget
// PlanCard & helper chip extracted to widgets/plan_card.dart
