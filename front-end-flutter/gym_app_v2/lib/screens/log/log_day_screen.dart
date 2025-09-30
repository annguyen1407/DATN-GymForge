import 'package:flutter/material.dart';
import '../../repositories/exercise_log_repository.dart';
import '../../repositories/meals_repository.dart';
import '../../models/meal_model.dart';
import '../../services/api_constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/plan_type_badge.dart';
import '../../widgets/pill_tab_bar.dart';
import 'log_workoutday_screen.dart';
import 'tabs/notes_tab.dart';
import 'tabs/plans_tab.dart';
import 'tabs/body_tab.dart';
import 'tabs/nutrition_tab.dart';

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

  late TabController _tabController;
  late Map<String, dynamic> _bodyMetrics;
  late List<String> _notes;

  // Dynamic meals fetched from API
  final MealsRepository _mealsRepo = MealsRepository();
  List<Meal> _meals = [];
  bool _loadingMeals = false;
  String? _mealsError;
  int? _caloriesBurned; // from daily summary (preferred)

  // Grouped structure for NutritionTab (mirrors previous shape)
  List<Map<String, dynamic>> get _nutritionData {
    final Map<MealType, List<Meal>> bucket = {
      MealType.breakfast: [],
      MealType.lunch: [],
      MealType.dinner: [],
      MealType.snack: [],
      MealType.unknown: [],
    };
    for (final m in _meals) {
      bucket.putIfAbsent(m.type, () => []);
      bucket[m.type]!.add(m);
    }
    List<Map<String, dynamic>> sections = [];
    void addSection(MealType t, String label) {
      sections.add({
        'meal': label,
        'foods': bucket[t]!
            .map((e) => {'id': e.id, 'name': e.name, 'calories': e.calories})
            .toList(),
      });
    }

    addSection(MealType.breakfast, 'Breakfast');
    addSection(MealType.lunch, 'Lunch');
    addSection(MealType.dinner, 'Dinner');
    // Optionally snacks (not in UI before)
    // addSection(MealType.snack, 'Snack');
    return sections;
  }

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
    final w = widget.weight; // remove mock defaults
    final h = widget.height;
    _bodyMetrics = {
      'weight': w,
      'height': h,
      'bmi': (w != null && h != null) ? _bmi(w, h) : null,
    };
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
    // Fetch meals after first frame to avoid build jank
    // Lazy load meals: only fetch when Nutrition tab opened first time
    _tabController.addListener(() {
      if (_tabController.index == 3 && _meals.isEmpty && !_loadingMeals) {
        _fetchMeals();
      }
    });
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
        if (summary.weight != null) {
          _bodyMetrics['weight'] = summary.weight!;
        }
        if (summary.height != null) {
          _bodyMetrics['height'] = summary.height!;
        }
        _caloriesBurned = summary.caloriesBurned;
        final bw = _bodyMetrics['weight'];
        final bh = _bodyMetrics['height'];
        _bodyMetrics['bmi'] = (bw != null && bh != null) ? _bmi(bw, bh) : null;
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

  Future<void> _fetchMeals() async {
    setState(() {
      _loadingMeals = true;
      _mealsError = null;
    });
    try {
      final list = await _mealsRepo.getMealsForDay(date: widget.selectedDate);
      if (!mounted) return;
      setState(() => _meals = list);
    } catch (e) {
      if (mounted) {
        setState(() => _mealsError = e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải bữa ăn: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMeals = false);
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
        'workoutExercise':
            item['workoutExercise'], // Giữ nguyên object chứa exerciseId
        'progress': prog,
        'totalTime': item['totalTime'], // Thêm totalTime từ log gốc
        // Các trường cũ giữ lại để tương thích UI
        'name': item['exerciseName'] ?? item['name'] ?? 'Bài tập',
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
    if (dnRaw is int) {
      dn = dnRaw;
    } else if (dnRaw is String) {
      dn = int.tryParse(dnRaw);
    }
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
        // Semi-transparent background (approx 15% alpha)
        color: Colors.redAccent.withAlpha(38),
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

  // Notes UI extracted to NotesTab widget

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
    final w = _bodyMetrics['weight'];
    final h = _bodyMetrics['height'];
    _bodyWeightController.text = w == null
        ? ''
        : (w as double).toStringAsFixed(1);
    _bodyHeightController.text = h == null
        ? ''
        : (h as double).toStringAsFixed(1);
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
                      setState(() {
                        _bodyMetrics['weight'] = (w != null && w > 0)
                            ? w
                            : null;
                        _bodyMetrics['height'] = (h != null && h > 0)
                            ? h
                            : null;
                        final nw = _bodyMetrics['weight'];
                        final nh = _bodyMetrics['height'];
                        _bodyMetrics['bmi'] = (nw != null && nh != null)
                            ? _bmi(nw as double, nh as double)
                            : null;
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
                    onPressed: () async {
                      final name = _foodNameController.text.trim();
                      final cal = double.tryParse(_foodCaloriesController.text);
                      if (name.isEmpty || cal == null || cal <= 0) return;
                      Navigator.pop(ctx);
                      // Determine meal type from label
                      final label = meal['meal'] as String? ?? '';
                      MealType type;
                      switch (label.toLowerCase()) {
                        case 'breakfast':
                          type = MealType.breakfast;
                          break;
                        case 'lunch':
                          type = MealType.lunch;
                          break;
                        case 'dinner':
                          type = MealType.dinner;
                          break;
                        default:
                          type = MealType.snack;
                      }
                      // Optimistic local add placeholder
                      final temp = Meal(
                        id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
                        name: name,
                        calories: cal.toInt(),
                        protein: null,
                        carbs: null,
                        fat: null,
                        type: type,
                        eatenAt: widget.selectedDate,
                      );
                      setState(() => _meals = [..._meals, temp]);
                      final created = await _mealsRepo.addMeal(
                        date: widget.selectedDate,
                        name: name,
                        calories: cal.toInt(),
                        type: type,
                      );
                      if (!mounted) return;
                      if (created != null) {
                        setState(() {
                          _meals = [
                            for (final m in _meals)
                              if (m.id == temp.id) created else m,
                          ];
                        });
                      } else {
                        // rollback
                        setState(() {
                          _meals = [
                            for (final m in _meals)
                              if (m.id != temp.id) m,
                          ];
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thêm bữa ăn thất bại')),
                        );
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

  @override
  Widget build(BuildContext context) {
    final caloriesIntake = _meals.fold<int>(0, (s, m) => s + m.calories);
    final caloriesBurned =
        _caloriesBurned ??
        widget.workouts.fold<int>(
          0,
          (s, w) =>
              s +
              (((w['sets'] ?? 0) as int) *
                      ((w['reps'] ?? 0) as int) *
                      ((w['weight'] ?? 0.0) as double) *
                      0.1)
                  .toInt(),
        );
    // ratio now computed internally by NutritionTab

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
                NotesTab(
                  note: _notes.isNotEmpty ? _notes.first : null,
                  onEdit: _showEditNoteModal,
                ),
                PlansTab(
                  plans: _planData,
                  planTypeColor: _planTypeColor,
                  dayBadgeBuilder: _dayBadge,
                  onOpenPlan: (plan) => Navigator.push(
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
                ),
                BodyTab(
                  weight: _bodyMetrics['weight'] is double
                      ? _bodyMetrics['weight'] as double
                      : null,
                  height: _bodyMetrics['height'] is double
                      ? _bodyMetrics['height'] as double
                      : null,
                  bmi: _bodyMetrics['bmi'] is double
                      ? _bodyMetrics['bmi'] as double
                      : null,
                  onEdit: _showEditBodyMetrics,
                ),
                Column(
                  children: [
                    if (_loadingMeals)
                      const LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF8854FF)),
                      )
                    else if (_mealsError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        color: Colors.redAccent.withAlpha(38),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$_mealsError',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: _fetchMeals,
                              child: const Text(
                                'Thử lại',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: NutritionTab(
                        meals: _nutritionData,
                        totalIntake: caloriesIntake,
                        totalBurned: caloriesBurned,
                        onAddFood: _showAddFood,
                        onRemoveFood: (meal, index) {
                          final foods =
                              meal['foods'] as List<Map<String, dynamic>>;
                          if (index < 0 || index >= foods.length) return;
                          final id = foods[index]['id']?.toString();
                          if (id == null) return;
                          final backup = _meals;
                          setState(
                            () => _meals = [
                              for (final m in _meals)
                                if (m.id != id) m,
                            ],
                          );
                          final messenger = ScaffoldMessenger.of(context);
                          _mealsRepo
                              .deleteMeal(date: widget.selectedDate, mealId: id)
                              .then((ok) {
                                if (!ok) {
                                  if (!mounted) return;
                                  setState(() => _meals = backup);
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Xóa bữa ăn thất bại'),
                                    ),
                                  );
                                }
                              });
                        },
                      ),
                    ),
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
