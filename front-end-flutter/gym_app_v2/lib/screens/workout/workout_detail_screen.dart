import 'package:flutter/material.dart';
import '../../widgets/workout_exercise_card.dart';
import '../../widgets/exercise_card.dart';
import 'workout_exercise_detail_screen.dart';

/// WorkoutDetailScreen: Màn hình chi tiết kế hoạch tập luyện khi click vào WorkoutCard
/// Hiển thị danh sách các ngày tập của một kế hoạch tập luyện
class WorkoutDetailScreen extends StatefulWidget {
  final String image;
  final String title;
  final String? subtitle;
  final String? description;
  final List<WorkoutExercise>? exercises; // Danh sách các ngày tập

  const WorkoutDetailScreen({
    required this.image,
    required this.title,
    this.subtitle,
    this.description,
    this.exercises,
    super.key,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  int? selectedExerciseIndex; // Index của ngày tập được chọn

  @override
  void initState() {
    super.initState();
    // Tự động chọn ngày tập đầu tiên chưa hoàn thành
    if (widget.exercises != null && widget.exercises!.isNotEmpty) {
      selectedExerciseIndex = widget.exercises!.indexWhere(
        (e) => !e.isCompleted,
      );
      // Nếu tất cả đã hoàn thành, chọn ngày cuối cùng
      if (selectedExerciseIndex == -1) {
        selectedExerciseIndex = widget.exercises!.length - 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header với hình nền - chiều cao cố định
          Container(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                // Hình nền
                Positioned.fill(
                  child: widget.image.isNotEmpty
                      ? Image.asset(
                          widget.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.deepPurple[300]),
                        )
                      : Container(color: Colors.deepPurple[300]),
                ),
                // Overlay gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // App bar buttons
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
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nội dung chi tiết - phần còn lại của màn hình
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề và thông tin cơ bản
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Thông tin thời lượng và buổi tập
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.exercises?.length ?? 0} ngày',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.people, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        '2 tuần',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ],
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      widget.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Danh sách ngày tập trong khung cố định
                  if (widget.exercises != null &&
                      widget.exercises!.isNotEmpty) ...[
                    const Text(
                      'Lịch trình tập luyện',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Container có chiều cao cố định với scroll riêng
                    Container(
                      height: 320, // Tăng chiều cao một chút
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header của danh sách
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.exercises!.length} ngày tập',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${widget.exercises!.where((e) => e.isCompleted).length}/${widget.exercises!.length} hoàn thành',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(height: 0.5, color: Colors.grey[700]),
                          // Danh sách có thể scroll
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: widget.exercises!.length,
                              itemBuilder: (context, index) {
                                final exercise = widget.exercises![index];

                                return WorkoutExerciseCard(
                                  exerciseNumber: index + 1,
                                  title: exercise.title,
                                  description: exercise.description,
                                  isActive:
                                      selectedExerciseIndex ==
                                      index, // Sử dụng selectedIndex
                                  isCompleted: exercise.isCompleted,
                                  onTap: () {
                                    // Chỉ select ngày tập, không navigate
                                    setState(() {
                                      selectedExerciseIndex = index;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  // Thêm ngày tập luyện button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Thêm ngày tập luyện',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Bắt đầu luyện tập button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedExerciseIndex != null
                          ? () {
                              // Navigate tới WorkoutExerciseDetailScreen của ngày được chọn
                              final selectedExercise =
                                  widget.exercises![selectedExerciseIndex!];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WorkoutExerciseDetailScreen(
                                        dayTitle: selectedExercise.title,
                                        date: _getWorkoutDate(
                                          selectedExerciseIndex!,
                                        ), // Ngày tháng năm động
                                        calories: '200 calories',
                                        backgroundImage: widget.image,
                                        exercises: _generateSampleExercises(),
                                      ),
                                ),
                              );
                            }
                          : null, // Disable nếu chưa chọn ngày nào
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedExerciseIndex != null
                            ? Colors.purple
                            : Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        selectedExerciseIndex != null
                            ? 'Bắt đầu ${widget.exercises![selectedExerciseIndex!].title}'
                            : 'Chọn ngày tập để bắt đầu',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tạo dữ liệu mẫu cho các bài tập trong ngày
  List<ExerciseItem> _generateSampleExercises() {
    return [
      const ExerciseItem(
        name: 'Jump rope',
        reps: '3 rep',
        image: 'assets/images/jump_rope.jpg',
      ),
      const ExerciseItem(
        name: 'Jumping jacks',
        reps: '3 rep',
        image: 'assets/images/jumping_jacks.jpg',
      ),
      const ExerciseItem(
        name: 'Jog in place',
        reps: '3 rep',
        image: 'assets/images/jog_in_place.jpg',
      ),
      const ExerciseItem(
        name: 'Split snatches',
        reps: '3 rep',
        image: 'assets/images/split_snatches.jpg',
      ),
      const ExerciseItem(
        name: 'Squat thrust split jumps',
        reps: '3 rep',
        image: 'assets/images/squat_thrust.jpg',
      ),
      const ExerciseItem(
        name: 'Plyometric woodchopper',
        reps: '3 rep',
        image: 'assets/images/woodchopper.jpg',
      ),
      const ExerciseItem(
        name: 'Plank jack',
        reps: '3 rep',
        image: 'assets/images/plank_jack.jpg',
      ),
      const ExerciseItem(
        name: 'Skaters',
        reps: '3 rep',
        image: 'assets/images/skaters.jpg',
      ),
      const ExerciseItem(
        name: 'Rollbacks',
        reps: '3 rep',
        image: 'assets/images/rollbacks.jpg',
      ),
    ];
  }

  /// Tạo ngày tháng cho workout dựa trên index
  String _getWorkoutDate(int dayIndex) {
    final now = DateTime.now();
    final workoutDate = now.add(Duration(days: dayIndex));
    return '${workoutDate.day}/${workoutDate.month}/${workoutDate.year}';
  }
}

/// Model cho ngày tập luyện
class WorkoutExercise {
  final String title; // Tên ngày tập (VD: "Ngày 1", "Ngày 2")
  final String description; // Mô tả ngày tập (VD: "Khởi động cơ bản - 30 phút")
  final bool isCompleted; // Đã hoàn thành ngày tập này chưa

  const WorkoutExercise({
    required this.title,
    required this.description,
    this.isCompleted = false,
  });
}
