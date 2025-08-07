// Dùng ở: log_screen. Tab chuyển đổi giữa các loại nhật ký.
import 'package:flutter/material.dart';

// File không sử dụng
class LogTab extends StatelessWidget {
  final String label;
  final bool selected;
  const LogTab({required this.label, this.selected = false, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: 48,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF8854FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
