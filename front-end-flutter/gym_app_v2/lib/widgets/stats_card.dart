// Dùng ở: log_screen. Card thống kê tổng quan.
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  // Lấy dữ liệu hôm nay từ LogWorkoutTimeCard (27/08/2025 = Wednesday = 2.2 giờ)
  double get todayHours => 2.2;
  int get todayCalories => (todayHours * 300).toInt(); // 2.2 * 300 = 660 cal
  int get todayWorkoutSets => (todayHours * 3).toInt(); // 2.2 * 3 = 6 sets
  String get todayTimeFormatted {
    final hours = todayHours.floor();
    final minutes = ((todayHours - hours) * 60).round();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DesignTokens.surface, DesignTokens.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
        border: Border.all(
          color: DesignTokens.surfaceOutline.withOpacity(.4),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: DesignTokens.spaceL - 4),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.warning.withOpacity(.85),
                  DesignTokens.warning,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.warning.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    todayWorkoutSets.toString(),
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(
                    'Workout Sets',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 70),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  Icons.access_time_rounded,
                  DesignTokens.info,
                  todayTimeFormatted,
                  'Total Time',
                ),
                const SizedBox(height: 12), // Reduced from 16
                _buildStatRow(
                  Icons.local_fire_department_rounded,
                  DesignTokens.warning,
                  '$todayCalories cal',
                  'Burned',
                ),
                const SizedBox(height: 12), // Reduced from 16
                _buildStatRow(
                  Icons.diamond_rounded,
                  DesignTokens.success,
                  '${(todayWorkoutSets * 50)} Points',
                  'Collected',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    Color iconColor,
    String value,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            label,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
