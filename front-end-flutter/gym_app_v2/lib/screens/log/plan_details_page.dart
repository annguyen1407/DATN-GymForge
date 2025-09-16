import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../widgets/stats_card.dart';
import './workout_info.dart';

/// PlanDetailsPage: Displays details of a workout plan, including exercises and completion gauges
class PlanDetailsPage extends StatelessWidget {
  final String planName;
  final List<Map<String, dynamic>> exercises;

  const PlanDetailsPage({
    required this.planName,
    required this.exercises,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate average progress for the plan
    final averageProgress = exercises.isNotEmpty
        ? exercises
                  .map((e) => e['progress'] as double)
                  .reduce((a, b) => a + b) /
              exercises.length
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          planName,
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
          child: exercises.isEmpty
              ? const Center(
                  child: Text(
                    'No exercises in this plan',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Buổi tập 1',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Bạn đã hoàn thành bài tập',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StatsCard(),
                      const SizedBox(height: 16),
                      Center(
                        child: LinearPercentIndicator(
                          width: null, // Expand to full width of parent
                          lineHeight: 40.0, // Larger bar
                          percent: averageProgress,
                          progressColor: Colors.orange.shade400,
                          backgroundColor: Colors.grey[800]!,
                          barRadius: const Radius.circular(5),
                          center: Text(
                            '${(averageProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              'Finished workout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: exercises.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final exercise = exercises[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WorkoutInfoPage(exercise: exercise),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        LinearPercentIndicator(
                                          lineHeight: 20.0,
                                          percent: exercise['progress'],
                                          progressColor: Colors.orange.shade400,
                                          backgroundColor: Colors.grey[800]!,
                                          barRadius: const Radius.circular(5),
                                          center: Text(
                                            '${(exercise['progress'] * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
