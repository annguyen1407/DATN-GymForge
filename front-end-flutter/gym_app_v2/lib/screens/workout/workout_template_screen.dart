import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';

class WorkoutTemplateScreen extends StatelessWidget {
  final String image;
  final String title;
  final String? tag;
  final int? exercises;
  final List<String>? workoutList;

  const WorkoutTemplateScreen({
    super.key,
    required this.image,
    required this.title,
    this.tag,
    this.exercises,
    this.workoutList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Nếu không có ảnh, dùng Container màu
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(color: Colors.deepPurple[300]),
                  child: image.isNotEmpty
                      ? Image.asset(
                          image,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.deepPurple[300]),
                        )
                      : null,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tag == 'Free' ? Colors.redAccent : Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${exercises ?? 12} bài tập',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      Icon(Icons.timer, color: Colors.white70, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Độ bền bị theo thời gian',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      Icon(
                        Icons.verified_user,
                        color: Colors.white70,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Được tham vấn bởi chuyên gia',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // TabBar
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      indicatorColor: Color(0xFF8854FF),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      tabs: const [
                        Tab(text: 'Workout list'),
                        Tab(text: 'Overview'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Workout list
                          ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            itemCount: workoutList?.length ?? 4,
                            itemBuilder: (context, idx) {
                              final name =
                                  workoutList != null &&
                                      idx < workoutList!.length
                                  ? workoutList![idx]
                                  : [
                                      'Jump rope',
                                      'Jumping jacks',
                                      'Jog in place',
                                      'Split snatches',
                                    ][idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.deepPurple[300],
                                        // Có thể thêm icon minh hoạ ở đây nếu muốn
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Overview
                          Center(
                            child: Text(
                              'Overview content',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: AppButton.primary(
                label: 'Thêm vào kế hoạch',
                onPressed: () {},
                size: AppButtonSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
