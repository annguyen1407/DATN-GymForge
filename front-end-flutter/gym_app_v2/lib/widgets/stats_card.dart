// Dùng ở: log_screen. Card thống kê tổng quan.
import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(24), // Reduced from 24
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[800]!, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            width: 100, // Reduced from 140
            height: 100, // Reduced from 140
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 12, // Reduced from 20
                  offset: const Offset(0, 6), // Reduced from (0, 8)
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 32, // Reduced from 44
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(
                    'Workout Sets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11, // Reduced from 12.9
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 70), // Reduced from 70
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  Icons.access_time_rounded,
                  Colors.blue.shade400,
                  todayTimeFormatted,
                  'Total Time',
                ),
                const SizedBox(height: 12), // Reduced from 16
                _buildStatRow(
                  Icons.local_fire_department_rounded,
                  Colors.orange.shade500,
                  '$todayCalories cal',
                  'Burned',
                ),
                const SizedBox(height: 12), // Reduced from 16
                _buildStatRow(
                  Icons.diamond_rounded,
                  Colors.cyan.shade400,
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
            Icon(icon, color: iconColor, size: 18), // Reduced from 22
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Reduced from 16
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
              color: Colors.white60,
              fontSize: 12, // Reduced from 13
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
