import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
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

  double _averageProgress() => exercises.isNotEmpty
      ? exercises
                .map((e) => (e['progress'] as double))
                .reduce((a, b) => a + b) /
            exercises.length
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final avg = _averageProgress();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          planName,
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: exercises.isEmpty
              ? const Center(
                  child: Text(
                    'Không có bài tập',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _headerCard(avg)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(
                          'Danh sách bài tập',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 4),
                      sliver: SliverList.separated(
                        itemBuilder: (ctx, i) =>
                            _exerciseItem(context, exercises[i]),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: exercises.length,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _headerCard(double avg) {
    final percentLabel = '${(avg * 100).toStringAsFixed(0)}%';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 46,
            lineWidth: 8,
            percent: avg.clamp(0.0, 1.0),
            center: Text(
              percentLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            progressColor: const Color(0xFF8854FF),
            backgroundColor: Colors.grey[800]!,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Số bài tập: ${exercises.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                _progressBarInline(avg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBarInline(double p) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: p.clamp(0.0, 1.0),
      minHeight: 8,
      backgroundColor: Colors.grey[800],
      valueColor: const AlwaysStoppedAnimation(Color(0xFF8854FF)),
    ),
  );

  Widget _exerciseItem(BuildContext context, Map<String, dynamic> e) {
    final progress = (e['progress'] as double).clamp(0.0, 1.0);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(
            exerciseName: e['name'].toString(),
            author: 'author',
            calories: '100',
            description: e['description']?.toString() ?? '',
            backgroundImage: 'bg',
            specs: const [],
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      splashColor: const Color(0x558854FF),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[850]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['name'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (e['description']?.toString().isNotEmpty ?? false)
                            ? e['description'].toString()
                            : 'Chưa có mô tả',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF8854FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation(Color(0xFF8854FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
