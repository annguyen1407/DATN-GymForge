// Dùng ở: exercise_screen. Card nhóm bài tập.
import 'package:flutter/material.dart';

// File không sử dụng
/// Widget hiển thị thẻ nhóm bài tập với tên, số lượng và highlight nếu là nhóm đặc biệt.
///
/// [name]: Tên nhóm bài tập.
/// [count]: Số lượng bài tập trong nhóm.
/// [highlight]: Nhóm này có nổi bật không (ví dụ: "Tất cả").
class ExerciseGroupCard extends StatelessWidget {
  final String name;
  final int count;
  final bool highlight;
  final VoidCallback? onTap;

  /// Tạo một ExerciseGroupCard
  const ExerciseGroupCard({
    required this.name,
    required this.count,
    this.highlight = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Container bọc ngoài, bo góc và nền tối
    return Material(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF444648), Color(0xFF2A2C2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 22,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: highlight ? Colors.pinkAccent : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
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
      ),
    );
  }
}
