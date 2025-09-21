import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'log_workoutday_screen.dart'; // contains WorkoutLogScreen

/// LogOfDayScreen: Displays detailed workout information for a selected date with tabs
class LogOfDayScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> workouts; // existing workouts list
  final void Function(Map<String, dynamic>)? onWorkoutAdded;

  const LogOfDayScreen({
    super.key,
    required this.selectedDate,
    required this.workouts,
    this.onWorkoutAdded,
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

  final Map<String, dynamic> _bodyMetrics = {
    'weight': 70.0,
    'height': 175.0,
    'bmi': 70.0 / (1.75 * 1.75),
  };

  final List<String> _notes = [];
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
  final List<Map<String, dynamic>> _planData = [];

  @override
  void initState() {
    super.initState();
    // Fix: TabController length must match number of tabs (4) and use proper vsync
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didUpdateWidget(covariant LogOfDayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        title: Text(
          'Workouts on ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF8854FF),
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Ghi chú'),
            Tab(text: 'Kế hoạch'),
            Tab(text: 'Cơ thể'),
            Tab(text: 'Dinh dưỡng'),
          ],
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
                          return GestureDetector(
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
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tiến độ: ${(plan['progress'] * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/workout.jpeg', // Replace with your image asset path
                                      width: 120,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  // Function to show modal for adding a new workout
}
