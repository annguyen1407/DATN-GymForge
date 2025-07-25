import 'package:flutter/material.dart';
import '../../widgets/exercise_card.dart';

/// WorkoutExerciseDetailScreen: Màn hình chi tiết một ngày tập luyện
/// Hiển thị danh sách các bài tập trong một ngày tập cụ thể
class WorkoutExerciseDetailScreen extends StatefulWidget {
  final String dayTitle; // Tên ngày tập (VD: "Buổi tập 1")
  final String date; // Ngày tháng năm (VD: "1/4/2025")
  final String calories; // Calories (VD: "200 calories")
  final String backgroundImage; // Hình nền
  final List<ExerciseItem> exercises; // Danh sách bài tập trong ngày

  const WorkoutExerciseDetailScreen({
    required this.dayTitle,
    required this.date,
    required this.calories,
    required this.backgroundImage,
    required this.exercises,
    super.key,
  });

  @override
  State<WorkoutExerciseDetailScreen> createState() =>
      _WorkoutExerciseDetailScreenState();
}

class _WorkoutExerciseDetailScreenState
    extends State<WorkoutExerciseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header với hình nền và thông tin ngày tập
          Container(
            height: 400,
            width: double.infinity,
            child: Stack(
              children: [
                // Hình nền
                Positioned.fill(
                  child: widget.backgroundImage.isNotEmpty
                      ? Image.asset(
                          widget.backgroundImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.purple[400]!,
                                      Colors.purple[800]!,
                                    ],
                                  ),
                                ),
                              ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.purple[400]!,
                                Colors.purple[800]!,
                              ],
                            ),
                          ),
                        ),
                ),
                // Overlay gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                // App bar
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Thông tin ngày tập
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.date,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.calories,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You\'ll Need',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Equipment needed - với số lượng items
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '2 Items',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildEquipmentItem('Barbell', Icons.fitness_center),
                          const SizedBox(width: 16),
                          _buildEquipmentItem(
                            'Skipping Rope',
                            Icons.sports_gymnastics,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Danh sách bài tập
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header danh sách bài tập - loại bỏ "5 Items" ở đây vì đã có ở trên
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.exercises.length} bài tập',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Danh sách bài tập có thể scroll
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = widget.exercises[index];
                        return ExerciseCard(
                          exercise: exercise,
                          index: index,
                          onTap: () {
                            // TODO: Xử lý khi bấm play button
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Button bắt đầu tập luyện
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Xử lý bắt đầu tập luyện
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFFF6B6B,
                ), // Màu đỏ như trong hình
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Khởi động bài tập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      // Floating Action Button như trong hình
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 80,
        ), // Đẩy lên trên để tránh button
        child: FloatingActionButton(
          onPressed: () {
            // TODO: Thêm bài tập mới
          },
          backgroundColor: const Color(0xFFFF6B6B), // Màu đỏ giống button
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  /// Widget hiển thị equipment cần thiết
  Widget _buildEquipmentItem(String name, IconData icon) {
    return Container(
      width: 120, // Chiều rộng cố định như trong hình
      height: 80, // Chiều cao cố định
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
