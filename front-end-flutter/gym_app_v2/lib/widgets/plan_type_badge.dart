import 'package:flutter/material.dart';
import '../core/extensions/color_extensions.dart';

/// Reusable unified badge for displaying a workout plan type across the app.
/// Usage: PlanTypeBadge(planType: 'STRENGTH')
class PlanTypeBadge extends StatelessWidget {
  final String? planType; // may be null -> show placeholder label
  final bool dense; // smaller padding variant if needed
  final double? fontSize;
  const PlanTypeBadge({
    super.key,
    required this.planType,
    this.dense = false,
    this.fontSize,
  });

  static const Map<String, String> _vn = {
    'STRENGTH': 'Sức mạnh',
    'CARDIO': 'Sức bền',
    'FLEXIBILITY': 'Dẻo dai',
    'COMBINED': 'Kết hợp',
  };

  /// Public helper: base color for a given plan type (used by cards for gradients)
  static Color baseColor(String? t) {
    switch (t) {
      // Sức mạnh: đỏ đậm thể hiện power / intensity
      case 'STRENGTH':
        return const Color(0xFFD32F2F); // Red 700
      // Sức bền (Cardio): cam rực biểu tượng năng lượng / nhịp tim kéo dài
      case 'CARDIO':
        return const Color(0xFFFB8C00); // Orange 600
      // Dẻo dai (Flexibility): teal dịu liên tưởng sự mềm dẻo / cân bằng
      case 'FLEXIBILITY':
        return const Color(0xFF26A69A); // Teal 400 (giữ nguyên)
      // Kết hợp: tím đậm tạo cảm giác tổng hợp đa yếu tố (strength + calm + focus)
      case 'COMBINED':
        return const Color(0xFF7E57C2); // Deep Purple 400
      default:
        return const Color(0xFF607D8B);
    }
  }

  /// Public helper: localized VN label (can be reused elsewhere if needed)
  static String localizedLabel(String? t) =>
      t == null ? 'Chưa chọn' : (_vn[t] ?? t);

  @override
  Widget build(BuildContext context) {
    final color = baseColor(planType);
    final lbl = localizedLabel(planType);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 14,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacityRatio(.80), color.withOpacityRatio(.45)],
        ),
        border: Border.all(color: Colors.white.withOpacityRatio(.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacityRatio(.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fitness_center, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            lbl,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize ?? (dense ? 11.5 : 12.5),
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }
}
