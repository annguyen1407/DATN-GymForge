import 'package:flutter/material.dart';

class LogTab extends StatelessWidget {
  final String label;
  final bool selected;
  const LogTab({required this.label, this.selected = false, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF8854FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
