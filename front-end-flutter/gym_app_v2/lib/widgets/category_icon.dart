// Dùng ở: log_screen, workout_screen. Hiển thị icon tròn có badge cho category/action nhanh.
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// A reusable widget that displays a circular icon with an optional count badge and a label below.
///
/// Used for category selection or quick actions in the app.
///
/// [icon]: The icon to display inside the circle.
/// [color]: The main color for the icon and background.
/// [label]: The text label shown below the icon.
/// [count]: (Optional) If provided, shows a badge with this number on the icon.
/// Widget hiển thị một icon tròn với badge số lượng tuỳ chọn và nhãn bên dưới.
///
/// Dùng cho các lựa chọn category hoặc action nhanh trong app.
///
/// [icon]: Icon hiển thị bên trong vòng tròn.
/// [color]: Màu chính cho icon và nền.
/// [label]: Nhãn hiển thị bên dưới icon.
/// [count]: (tuỳ chọn) Nếu có, sẽ hiển thị badge số lượng trên icon.
class CategoryIcon extends StatelessWidget {
  /// Icon hiển thị bên trong vòng tròn
  final IconData icon;

  /// Màu chính cho icon và nền
  final Color color;

  /// Nhãn hiển thị bên dưới icon
  final String label;

  /// Số lượng badge (nếu có)
  final int? count;

  /// Tạo một CategoryIcon
  const CategoryIcon({
    required this.icon,
    required this.color,
    required this.label,
    this.count,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Dùng Column để xếp icon và nhãn theo chiều dọc
    return Column(
      children: [
        // Stack để hiển thị icon tròn và badge số lượng (nếu có)
        Stack(
          children: [
            // Nền tròn với icon ở giữa
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(
                0.15,
              ), // giữ sắc độ theo màu truyền vào (category accent)
              child: Icon(icon, color: color, size: 28),
            ),
            // Nếu có count, hiển thị badge số lượng ở góc trên bên phải
            if (count != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.brandGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: DesignTokens.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.brand.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Nhãn hiển thị bên dưới icon
        Text(
          label,
          style: TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }
}
