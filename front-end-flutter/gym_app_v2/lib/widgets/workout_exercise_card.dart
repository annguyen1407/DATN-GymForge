import 'package:flutter/material.dart';

/// WorkoutExerciseCard: Widget hiển thị thông tin bài tập trong workout detail
class WorkoutExerciseCard extends StatelessWidget {
  final int exerciseNumber;
  final String title;
  final String description;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const WorkoutExerciseCard({
    required this.exerciseNumber,
    required this.title,
    required this.description,
    this.isActive = false,
    this.isCompleted = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.orange, width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Icon bài tập với số thứ tự
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _buildExerciseIcon(),
              ),
            ),
            const SizedBox(width: 12),
            // Thông tin bài tập
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Trạng thái icon bên phải
            _buildStatusIcon(),
          ],
        ),
      ),
    );
  }

  /// Xác định màu nền cho icon bài tập
  Color _getIconBackgroundColor() {
    if (isCompleted) {
      return Colors.green;
    } else if (isActive) {
      return Colors.orange;
    } else {
      return Colors.grey[800]!;
    }
  }

  /// Xây dựng icon trong container bài tập
  Widget _buildExerciseIcon() {
    if (isCompleted) {
      return const Icon(
        Icons.check,
        color: Colors.white,
        size: 20,
      );
    } else {
      return Text(
        '$exerciseNumber',
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    }
  }

  /// Xây dựng icon trạng thái bên phải
  Widget _buildStatusIcon() {
    if (isCompleted) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 20,
      );
    } else if (isActive) {
      return const Icon(
        Icons.play_circle_outline,
        color: Colors.orange,
        size: 20,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
