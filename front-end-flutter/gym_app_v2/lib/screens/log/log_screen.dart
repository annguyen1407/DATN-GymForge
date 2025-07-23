import 'package:flutter/material.dart';
import '../../widgets/log_tab.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/log_workout_time_card.dart';

/// LogScreen: Tab "Log" hiển thị lịch sử tập luyện, thống kê, các nhóm workout đã hoàn thành
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs chuyển giữa lịch sử và chuyên sâu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LogTab(label: 'Lịch sử', selected: true),
                  const SizedBox(width: 32),
                  LogTab(label: 'Chuyên sâu'),
                ],
              ),
              const SizedBox(height: 20),
              // Thống kê tổng quan
              const StatsCard(),
              const SizedBox(height: 24),
              // Danh sách nhóm workout đã hoàn thành
              const Text(
                'Workout sets',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your completed workout categories',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  CategoryIcon(
                    icon: Icons.directions_run,
                    color: Color(0xFFB86B5B),
                    label: 'Cardio',
                    count: 3,
                  ),
                  CategoryIcon(
                    icon: Icons.fitness_center,
                    color: Color(0xFF7B5FB2),
                    label: 'Strength',
                    count: 2,
                  ),
                  CategoryIcon(
                    icon: Icons.timer,
                    color: Color(0xFF4CB7A5),
                    label: 'Endurance',
                    count: 2,
                  ),
                  CategoryIcon(
                    icon: Icons.more_horiz,
                    color: Color(0xFF4C7CB7),
                    label: 'More',
                    count: 3,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Thời gian tập luyện
              const LogWorkoutTimeCard(),
            ],
          ),
        ),
      ),
    );
  }
}
