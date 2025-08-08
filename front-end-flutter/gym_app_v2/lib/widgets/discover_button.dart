// Dùng ở: home_screen. Nút khám phá nhanh các tính năng.
import 'package:flutter/material.dart';
import '../screens/coaches/coaches_screen.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/my_coach/my_coach_screen.dart';

// File không sử dụng
/// DiscoverButton: Nút khám phá trên trang Home
class DiscoverButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const DiscoverButton({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  State<DiscoverButton> createState() => _DiscoverButtonState();
}

class _DiscoverButtonState extends State<DiscoverButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToScreen(BuildContext context) {
    switch (widget.label.toLowerCase()) {
      case 'coaches':
      case 'huấn luyện viên':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CoachesScreen()),
        );
        break;
      case 'achievements':
      case 'thành tựu':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AchievementsScreen()),
        );
        break;
      case 'my coach':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyCoachScreen()),
        );
        break;
      default:
        // Fallback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tính năng ${widget.label} đang phát triển')),
        );
    }
  }

  IconData _getIconForLabel() {
    switch (widget.label.toLowerCase()) {
      case 'coaches':
      case 'huấn luyện viên':
      case 'trainer':
        return Icons.fitness_center;
      case 'achievements':
      case 'thành tựu':
        return Icons.emoji_events;
      case 'my coach':
      case 'my couch':
        return Icons.person_pin;
      default:
        return Icons.explore;
    }
  }

  Color _getColorForLabel() {
    switch (widget.label.toLowerCase()) {
      case 'coaches':
      case 'huấn luyện viên':
      case 'trainer':
        return Colors.blue;
      case 'achievements':
      case 'thành tựu':
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
    final iconData = widget.icon ?? _getIconForLabel();
    final color = widget.iconColor ?? _getColorForLabel();

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () => _navigateToScreen(context),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[850]!, Colors.grey[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[700]!.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: color.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          blurRadius: 1,
                          offset: const Offset(0, -1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withOpacity(0.15),
                            color.withOpacity(0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                      child: Icon(
                        iconData,
                        color: color.withOpacity(0.9),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
