// Dùng ở: exercise_screen. Card nhóm bài tập.
import 'package:flutter/material.dart';

/// Widget hiển thị thẻ nhóm bài tập với tên, số lượng và highlight nếu là nhóm đặc biệt.
///
/// [name]: Tên nhóm bài tập.
/// [count]: Số lượng bài tập trong nhóm.
/// [highlight]: Nhóm này có nổi bật không (ví dụ: "Tất cả").
class ExerciseGroupCard extends StatelessWidget {
  final String name;
  final int count;
  final bool highlight;

  /// Tạo một ExerciseGroupCard
  const ExerciseGroupCard({
    required this.name,
    required this.count,
    this.highlight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Container bọc ngoài, bo góc và nền tối
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Ảnh đại diện nhóm bài tập
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/exercise_group.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(width: 40, height: 40, color: Colors.grey[800]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Thông tin nhóm: tên và số lượng
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên nhóm, highlight nếu là nhóm đặc biệt
                Text(
                  name,
                  style: TextStyle(
                    color: highlight ? Colors.pinkAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                // Số lượng bài tập
                Text(
                  '$count bài tập',
                  style: TextStyle(
                    color: highlight ? Colors.pinkAccent : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
