import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../screens/log/plan_details_page.dart';

/// WorkoutDetailsPage: Displays detailed workout information for a selected date with tabs
class WorkoutDetailsPage extends StatefulWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> workouts;
  final Function(Map<String, dynamic>)? onWorkoutAdded; // Callback to update parent

  const WorkoutDetailsPage({
    required this.selectedDate,
    required this.workouts,
    this.onWorkoutAdded,
    super.key,
  });

  @override
  _WorkoutDetailsPageState createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Mock body metrics for the selected date (replace with backend data)
  final Map<String, dynamic> _bodyMetrics = {
    'weight': 70.0,
    'height': 175.0,
    'bodyFat': 20.0,
  };

  // Mock nutrition data for the selected date (replace with backend data)
  final List<Map<String, dynamic>> _nutritionData = [
    {'meal': 'Breakfast', 'calories': 500, 'protein': 30, 'carbs': 60, 'fat': 15},
    {'meal': 'Lunch', 'calories': 700, 'protein': 40, 'carbs': 80, 'fat': 20},
  ];

  // Mock plan data for the "Kế hoạch" tab
  final List<Map<String, dynamic>> _planData = [
    {
      'name': 'Kế hoạch 1',
      'progress': 0.8, // 80%
      'exercises': [
        {'name': 'Bench Press', 'progress': 0.9}, // 90%
        {'name': 'Squats', 'progress': 0.8}, // 80%
        {'name': 'Deadlift', 'progress': 0.7}, // 70%
      ],
    },
    {
      'name': 'Kế hoạch 2',
      'progress': 0.6, // 60%
      'exercises': [
        {'name': 'Push-Ups', 'progress': 0.7}, // 70%
        {'name': 'Lunges', 'progress': 0.6}, // 60%
        {'name': 'Pull-Ups', 'progress': 0.5}, // 50%
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Function to show modal for adding a new workout
  Future<void> _showAddWorkoutModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true, // Allow full height for keyboard
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
                'Add Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
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
                controller: _setsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Sets',
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
                controller: _repsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Reps',
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
                controller: _weightController,
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
                        // Validate and add workout
                        final name = _nameController.text.trim();
                        final sets = int.tryParse(_setsController.text);
                        final reps = int.tryParse(_repsController.text);
                        final weight = double.tryParse(_weightController.text);
                        if (name.isNotEmpty &&
                            sets != null &&
                            sets > 0 &&
                            reps != null &&
                            reps > 0 &&
                            weight != null &&
                            weight >= 0) {
                          final newWorkout = {
                            'name': name,
                            'sets': sets,
                            'reps': reps,
                            'weight': weight,
                          };
                          widget.onWorkoutAdded?.call(newWorkout);
                          setState(() {
                            widget.workouts.add(newWorkout);
                          });
                          _nameController.clear();
                          _setsController.clear();
                          _repsController.clear();
                          _weightController.clear();
                          Navigator.pop(context);
                        }
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          tabs: const [
            Tab(text: 'Ghi chú'),
            Tab(text: 'Kế hoạch'),
            Tab(text: 'Cơ thể'),
            Tab(text: 'Dinh dưỡng'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkoutModal(context),
        backgroundColor: const Color(0xFF8854FF),
        child: const Icon(Icons.add, color: Colors.white),
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
                  const Text(
                    'Notes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your notes for this day...',
                      hintStyle: const TextStyle(color: Colors.white54),
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
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final plan = _planData[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlanDetailsPage(
                                    planName: plan['name'],
                                    exercises: List<Map<String, dynamic>>.from(plan['exercises']),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    'Progress: ${(plan['progress'] * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearPercentIndicator(
                                    lineHeight: 10.0,
                                    percent: plan['progress'],
                                    progressColor: const Color(0xFF8854FF),
                                    backgroundColor: Colors.grey[800]!,
                                    barRadius: const Radius.circular(5),
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
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Body Metrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricItem('Weight', '${_bodyMetrics['weight'].toStringAsFixed(1)} kg'),
                        _buildMetricItem('Height', '${_bodyMetrics['height'].toStringAsFixed(1)} cm'),
                        _buildMetricItem('Body Fat', '${_bodyMetrics['bodyFat'].toStringAsFixed(1)}%'),
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
                  : ListView.separated(
                      itemCount: _nutritionData.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final meal = _nutritionData[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal['meal'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Calories: ${meal['calories']} kcal',
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                              Text(
                                'Protein: ${meal['protein']} g',
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                              Text(
                                'Carbs: ${meal['carbs']} g',
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                              Text(
                                'Fat: ${meal['fat']} g',
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
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
