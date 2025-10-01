import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../core/extensions/color_extensions.dart';

/// A minimal variation focusing only on name + muscle group labels.
/// Matches overall dark style & spacing conventions.
class ExerciseMinimalCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool dense;
  final int maxMuscleTags;

  const ExerciseMinimalCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.dense = false,
    this.maxMuscleTags = 4,
  });

  @override
  Widget build(BuildContext context) {
    final muscleTags = exercise.muscleGroupNames.take(maxMuscleTags).toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C21), Color(0xFF141417)],
          ),
          border: Border.all(color: Colors.white.withOpacityRatio(.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: dense ? 42 : 48,
              height: dense ? 42 : 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A2A30), Color(0xFF1A1A1D)],
                ),
                border: Border.all(color: Colors.white.withOpacityRatio(.07)),
              ),
              child: const Icon(Icons.fitness_center, color: Colors.white70),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: dense ? 15 : 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .3,
                      height: 1.15,
                    ),
                  ),
                  if (muscleTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: muscleTags.map((t) => _tag(t)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacityRatio(.30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacityRatio(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacityRatio(.14),
          width: 0.8,
        ),
      ),
      child: Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
