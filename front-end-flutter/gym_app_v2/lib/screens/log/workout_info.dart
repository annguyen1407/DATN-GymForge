import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// WorkoutInfoPage: Displays detailed information about a specific exercise
class WorkoutInfoPage extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const WorkoutInfoPage({required this.exercise, super.key});

  @override
  Widget build(BuildContext context) {
    // Extract exercise data
    final name = exercise['name'] as String;
    final progress = exercise['progress'] as double? ?? 0.0;
    // Mock values for sets, reps, weight if not provided
    final totalSets = exercise['sets'] as int? ?? 5;
    final reps = exercise['reps'] as int? ?? 10;
    final weight = exercise['weight'] as double? ?? 50.0;
    final completedSets = (totalSets * progress).toInt();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Exercise Name
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Basic Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Info',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sets: $totalSets',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Reps per Set: $reps',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Weight: ${weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Workout Count vs Goal
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workout Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completed: $completedSets / $totalSets sets',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Circular Percent Indicator
                CircularPercentIndicator(
                  radius: 60.0,
                  lineWidth: 10.0,
                  percent: progress,
                  center: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
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
        ),
      ),
    );
  }
}
