import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../widgets/discover_button.dart';
import '../../widgets/today_stats.dart';
import '../../widgets/workout_time_chart.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              48,
            ), // tăng bottom padding để tránh overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chào bạn,',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Khám phá
                const Text(
                  'Khám phá',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: DiscoverButton(label: 'Huấn luyện viên')),
                    const SizedBox(width: 12),
                    Expanded(child: DiscoverButton(label: 'Thành tựu')),
                    const SizedBox(width: 12),
                    Expanded(child: DiscoverButton(label: 'My couch')),
                  ],
                ),
                const SizedBox(height: 24),
                // Thống kê hôm nay
                const Text(
                  'Thống kê hôm nay',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const TodayStats(),
                const SizedBox(height: 24),
                // Thời gian tập luyện
                const Text(
                  'Thời gian tập luyện',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const WorkoutTimeChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
