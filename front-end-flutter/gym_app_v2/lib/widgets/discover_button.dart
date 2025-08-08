// Dùng ở: home_screen. Nút khám phá nhanh các tính năng.
import 'package:flutter/material.dart';

// File không sử dụng
/// DiscoverButton: Nút khám phá trên trang Home
class DiscoverButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const DiscoverButton({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  IconData _getIconForLabel() {
    switch (label.toLowerCase()) {
      case 'huấn luyện viên':
      case 'trainer':
        return Icons.fitness_center;
      case 'thành tựu':
      case 'achievements':
        return Icons.emoji_events;
      case 'my coach':
      case 'my couch':
        return Icons.person_pin;
      default:
        return Icons.explore;
    }
  }

  Color _getColorForLabel() {
    switch (label.toLowerCase()) {
      case 'huấn luyện viên':
      case 'trainer':
        return Colors.blue;
      case 'thành tựu':
      case 'achievements':
        return Colors.amber;
      case 'my coach':
      case 'my couch':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconData = icon ?? _getIconForLabel();
    final color = iconColor ?? _getColorForLabel();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[850]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[700]!.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(iconData, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
