import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../widgets/today_stat.dart';
import 'log_exercise_detail_screen.dart';

/// WorkoutLogScreen: Displays details of a workout plan/day log including exercises and completion gauges
class WorkoutLogScreen extends StatelessWidget {
  final String planName;
  final List<Map<String, dynamic>> exercises;

  const WorkoutLogScreen({
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
                      const TodayStat(
                        workoutSets: 6,
                        exercisesCount: 18,
                        calories: 660,
                        points: 300,
                        compact: true,
                        padding: EdgeInsets.all(20),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: LinearPercentIndicator(
                          width: null, // Expand to full width of parent
                          lineHeight: 60.0, // Larger bar
                          percent: averageProgress,
                          progressColor: Colors.orange.shade600,
                          backgroundColor: Colors.grey[800]!,
                          barRadius: const Radius.circular(10),
                          center: Text(
                            '${(averageProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(9, 0, 0, 0),
                              child: const Text(
                                'Finished workout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: exercises.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final exercise = exercises[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            // WorkoutInfoPage(exercise: exercise),
                                            ExerciseDetailScreen(
                                              exerciseName: exercise["name"]
                                                  .toString(),
                                              author: "author",
                                              calories: "100",
                                              description: "desc",
                                              backgroundImage: "bg",
                                              specs: [],
                                            ),
                                      ),
                                    );
                                  },
                                  // Finished Exercise with Progress Gauge
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LinearPercentIndicator(
                                        width: null,
                                        lineHeight: 60.0, // Larger bar
                                        percent: exercise['progress'],
                                        progressColor: Colors.orange.shade600,
                                        backgroundColor: Colors.grey[800]!,
                                        barRadius: const Radius.circular(10),
                                        center: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .start, // Aligns content to the start
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8.0,
                                              ), // Optional padding for better spacing
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    exercise['name'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  if (exercise['description'] !=
                                                          null &&
                                                      exercise['description']
                                                          .toString()
                                                          .isNotEmpty)
                                                    Text(
                                                      exercise['description']
                                                          .toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                  else
                                                    const Text(
                                                      'No description available',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
