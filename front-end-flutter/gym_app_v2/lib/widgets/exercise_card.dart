import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceAlt.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignTokens.surfaceOutline.withOpacity(.4),
            width: 0.5,
          ),
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
                color: exercise.image.isEmpty
                    ? DesignTokens.surfaceMuted
                    : null,
              ),
              child: exercise.image.isEmpty
                  ? const Icon(
                      Icons.fitness_center,
                      color: Colors.white54,
                      size: 20, // Giảm từ 24 xuống 20
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Thông tin bài tập
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (exercise.muscleGroupNames.isNotEmpty) ...[
                    Wrap(
                      spacing: 4,
                      runSpacing: -4,
                      children: exercise.muscleGroupNames.take(3).map((mg) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.brand.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mg,
                            style: const TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Hiển thị các thông số config
                  Row(
                    children: [
                      _buildSpecChip('${exercise.sets} hiệp', Icons.repeat),
                      const SizedBox(width: 8),
                      _buildSpecChip(
                        '${exercise.repsCount} reps',
                        Icons.fitness_center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildSpecChip(
                        '${exercise.weight}kg',
                        Icons.monitor_weight,
                      ),
                      const SizedBox(width: 8),
                      _buildSpecChip('${exercise.restTime}s', Icons.timer),
                    ],
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

  /// Widget hiển thị thông số config dạng chip nhỏ
  Widget _buildSpecChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceMuted.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DesignTokens.warning, size: 12),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Model cho một bài tập trong ngày với các thông số config
class ExerciseItem {
  final String? id; // id record của workout day exercise (d.id)
  final String?
  exerciseId; // id bài tập gốc (d.exerciseId) dùng để fetch chi tiết
  final String name; // Tên bài tập
  final String reps; // Số rép (giữ để tương thích với code cũ)
  final String image; // Đường dẫn hình ảnh
  final int sets; // Số hiệp
  final int repsCount; // Số reps dạng số
  final int weight; // Trọng lượng (kg)
  final int restTime; // Thời gian nghỉ (giây)
  final List<String> muscleGroupNames; // Nhóm cơ liên quan

  const ExerciseItem({
    this.id,
    this.exerciseId,
    required this.name,
    required this.reps,
    this.image = '',
    this.sets = 3,
    this.repsCount = 12,
    this.weight = 40,
    this.restTime = 120,
    this.muscleGroupNames = const [],
  });
}
