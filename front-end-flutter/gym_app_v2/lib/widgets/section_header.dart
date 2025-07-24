// Dùng ở: workout_screen. Header phân cách các section, có thể có nút "Xem tất cả".
import 'package:flutter/material.dart';

/// Widget hiển thị tiêu đề section với tuỳ chọn "See all".
///
/// [title]: Tiêu đề section.
/// [onSeeAll]: Callback khi nhấn "See all" (nếu có).
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  /// Tạo một SectionHeader
  const SectionHeader({required this.title, this.onSeeAll, super.key});

  @override
  Widget build(BuildContext context) {
    // Row để căn trái phải: tiêu đề và nút See all
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tiêu đề section
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        // Nút See all (nếu có callback)
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: TextStyle(
              color: Colors.purple[200],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
