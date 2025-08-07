import 'package:flutter/material.dart';
import '../../widgets/exercise_group_card.dart';

/// ExerciseScreen: Tab "Exercise" hiển thị danh sách nhóm bài tập, tìm kiếm, grid các nhóm
class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Danh sách các nhóm bài tập mẫu
    final List<Map<String, dynamic>> groups = [
      {'name': 'Triceps', 'count': 4},
      {'name': 'Forearms', 'count': 10},
      {'name': 'Chest', 'count': 5},
      {'name': 'Upper Legs', 'count': 12},
      {'name': 'Shoulders', 'count': 6},
      {'name': 'Glutes', 'count': 8},
      {'name': 'Biceps', 'count': 7},
      {'name': 'Cardio', 'count': 14},
      {'name': 'Core', 'count': 9},
      {'name': 'Lower Legs', 'count': 11},
      {'name': 'Back', 'count': 6},
      {'name': 'Tất cả', 'count': 86, 'highlight': true},
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Tiêu đề trang
            const Text(
              'Bài tập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Ô tìm kiếm bài tập
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, color: Colors.white54),
                    ),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Grid các nhóm bài tập
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  itemCount: groups.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.8,
                  ),
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return ExerciseGroupCard(
                      name: g['name'],
                      count: g['count'],
                      highlight: g['highlight'] == true,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Tạo bài tập riêng',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
