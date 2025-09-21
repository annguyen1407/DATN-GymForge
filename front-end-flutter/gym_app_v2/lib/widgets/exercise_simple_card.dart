import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../core/extensions/color_extensions.dart';

/// ExerciseSimpleCard: dùng chung cho danh sách bài tập (xem) và chọn thêm.
/// - Hiển thị tên, specs (sets x reps), rest, weight nếu có, mô tả ngắn & tags nhóm cơ.
/// - Chấp nhận onTap (selection) hoặc null (chỉ xem).
class ExerciseSimpleCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback? onTap;
  final bool compact; // nếu true: giảm padding & ẩn mô tả
  final bool showDescription;
  final bool showMuscleTags;
  final EdgeInsetsGeometry? padding;

  const ExerciseSimpleCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.compact = false,
    this.showDescription = true,
    this.showMuscleTags = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final hasDesc =
        (exercise.description != null && exercise.description!.isNotEmpty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                ),
                if (exercise.defaultSets != null &&
                    exercise.defaultReps != null)
                  _chip('${exercise.defaultSets}x${exercise.defaultReps}')
                else if (exercise.defaultSets != null)
                  _chip('${exercise.defaultSets} sets'),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: -4,
              children: [
                if (exercise.restTime != null)
                  _iconText(Icons.timer_outlined, '${exercise.restTime}s'),
                if (exercise.met != null)
                  _iconText(
                    Icons.local_fire_department_outlined,
                    '${exercise.met} MET',
                  ),
                if (exercise.defaultWeight != null)
                  _iconText(
                    Icons.fitness_center_outlined,
                    '${exercise.defaultWeight}kg',
                  ),
              ],
            ),
            if (!compact && showDescription && hasDesc) ...[
              const SizedBox(height: 8),
              Text(
                _stripPrefix(exercise.description!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            if (!compact &&
                showMuscleTags &&
                exercise.muscleGroupNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: exercise.muscleGroupNames
                    .take(3)
                    .map((n) => _tag(n))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withOpacityRatio(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.pinkAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _tag(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Text(
        t,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }

  String _stripPrefix(String s) {
    return s.replaceFirst(RegExp(r'^Mô tả:\s*'), '');
  }
}
