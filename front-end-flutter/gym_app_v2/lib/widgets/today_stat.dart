import 'package:flutter/material.dart';
import '../core/extensions/color_extensions.dart';
import '../theme/design_tokens.dart';

/// TodayStat: widget thống kê ngắn gọn trong ngày (gộp từ TodayStats & StatsCard cũ)
class TodayStat extends StatelessWidget {
  final int workoutSets; // hiển thị ở vòng tròn (số buổi / sessions)
  final int exercisesCount; // tổng số bài tập (workoutExerciseLogs)
  final int calories; // calories burned
  final int? caloriesIntake; // optional: calories đã nạp
  final int? points; // optional: điểm thưởng
  final int? workoutTimeMinutes; // optional: tổng phút tập trong ngày
  final String circleLabel; // nhãn trong vòng tròn
  final EdgeInsetsGeometry padding;
  final bool compact; // true: thu nhỏ cho log / plan, false: full cho home

  const TodayStat({
    super.key,
    required this.workoutSets,
    required this.exercisesCount,
    required this.calories,
    this.caloriesIntake,
    this.points,
    this.workoutTimeMinutes,
    this.circleLabel = 'Workout Sets',
    this.padding = const EdgeInsets.all(24),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = compact ? 100.0 : 140.0;
    final numberStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: compact ? 32 : 44,
      letterSpacing: .5,
    );
    final labelStyle = TextStyle(
      color: const Color.fromARGB(255, 255, 255, 255),
      fontSize: compact ? 11 : 12.5,
      fontWeight: FontWeight.w500,
    );
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.surface,
            DesignTokens.surfaceAlt.withOpacityRatio(.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DesignTokens.surfaceOutline.withOpacityRatio(.5),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityRatio(.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              // Updated: use brand purple gradient instead of warning (orange)
              gradient: LinearGradient(
                colors: [
                  DesignTokens.brandGradientStart.withOpacityRatio(.9),
                  DesignTokens.brandGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.brand.withOpacityRatio(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(workoutSets.toString(), style: numberStyle),
                  Text(circleLabel, style: labelStyle),
                ],
              ),
            ),
          ),
          SizedBox(width: compact ? 40 : 70),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  icon: Icons.fitness_center,
                  color: DesignTokens.info,
                  value: exercisesCount.toString(),
                  label: 'Số bài tập',
                  compact: compact,
                ),
                SizedBox(height: compact ? 12 : 16),
                if (workoutTimeMinutes != null) ...[
                  _buildStatRow(
                    icon: Icons.access_time_filled_rounded,
                    color: DesignTokens.brand,
                    value: _formatDuration(workoutTimeMinutes!),
                    label: 'Thời gian tập',
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 12 : 16),
                ],
                _buildStatRow(
                  icon: Icons.local_fire_department_rounded,
                  color: const Color.fromARGB(255, 255, 53, 53),
                  value: '$calories cal',
                  label: 'Calo đã đốt',
                  compact: compact,
                ),
                if (caloriesIntake != null) ...[
                  SizedBox(height: compact ? 12 : 16),
                  _buildStatRow(
                    icon: Icons.restaurant,
                    color: Colors.orangeAccent,
                    value: '$caloriesIntake cal',
                    label: 'Calo đã nạp',
                    compact: compact,
                  ),
                ],
                SizedBox(height: compact ? 12 : 16),
                if (points != null)
                  _buildStatRow(
                    icon: Icons.diamond_rounded,
                    color: DesignTokens.success,
                    value: '$points Points',
                    label: 'Collected',
                    compact: compact,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required bool compact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: compact ? 18 : 22),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w600,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white60,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '0 phút';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m phút';
    if (m == 0) return '$h giờ';
    return '$h giờ $m phút';
  }
}
