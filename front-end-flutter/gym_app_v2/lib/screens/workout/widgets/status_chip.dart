import 'package:flutter/material.dart';

/// Widget chip hiển thị trạng thái bài tập trong danh sách bài tập
class StatusChip extends StatelessWidget {
  final bool isActive;
  final bool isDone;
  final bool isSkipped;

  const StatusChip({
    Key? key,
    required this.isActive,
    required this.isDone,
    this.isSkipped = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    Color fg;
    if (isActive) {
      label = 'Đang tập';
      bg = const Color(0xFFFFF3E0).withOpacity(.9);
      fg = const Color(0xFFBF360C);
    } else if (isDone) {
      label = 'Xong';
      bg = const Color(0xFFE8F5E9).withOpacity(.9);
      fg = const Color(0xFF1B5E20);
    } else if (isSkipped) {
      label = 'Bỏ qua';
      bg = Colors.grey.withOpacity(.18);
      fg = Colors.grey.shade400;
    } else {
      label = 'Chờ';
      bg = Colors.white.withOpacity(.08);
      fg = Colors.white70;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFFBF360C).withOpacity(.5)
              : isDone
              ? const Color(0xFF1B5E20).withOpacity(.55)
              : isSkipped
              ? Colors.grey.withOpacity(.3)
              : Colors.white12,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: .3,
        ),
      ),
    );
  }
}
