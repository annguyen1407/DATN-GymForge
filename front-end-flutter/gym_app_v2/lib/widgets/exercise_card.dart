import 'package:flutter/material.dart';

/// ExerciseCard: Widget hiển thị thông tin một bài tập trong danh sách
class ExerciseCard extends StatelessWidget {
  final ExerciseItem exercise;
  final int index;
  final VoidCallback? onTap;

  const ExerciseCard({
    required this.exercise,
    required this.index,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), // Giảm margin từ 12 xuống 8
        padding: const EdgeInsets.all(12), // Giảm padding từ 16 xuống 12
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!, width: 0.5),
        ),
        child: Row(
          children: [
            // Hình ảnh bài tập - nhỏ hơn
            Container(
              width: 50, // Giảm từ 60 xuống 50
              height: 50, // Giảm từ 60 xuống 50
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: exercise.image.isNotEmpty
                    ? DecorationImage(
                        image: AssetImage(exercise.image),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: exercise.image.isEmpty ? Colors.grey[700] : null,
              ),
              child: exercise.image.isEmpty
                  ? const Icon(
                      Icons.fitness_center,
                      color: Colors.white54,
                      size: 20, // Giảm từ 24 xuống 20
                    )
                  : null,
            ),
            const SizedBox(width: 12), // Giảm từ 16 xuống 12
            // Thông tin bài tập
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15, // Giảm từ 16 xuống 15
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2), // Giảm từ 4 xuống 2
                  Text(
                    exercise.reps,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13, // Giảm từ 14 xuống 13
                    ),
                  ),
                ],
              ),
            ),
            // Bỏ play button - không cần icon tam giác nữa
          ],
        ),
      ),
    );
  }
}

/// Model cho một bài tập trong ngày
class ExerciseItem {
  final String name; // Tên bài tập
  final String reps; // Số lần/thời gian
  final String image; // Đường dẫn hình ảnh

  const ExerciseItem({required this.name, required this.reps, this.image = ''});
}
