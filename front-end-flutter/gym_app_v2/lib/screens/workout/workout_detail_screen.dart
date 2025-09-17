import 'package:flutter/material.dart';
import '../../widgets/workout_exercise_card.dart';
import 'workout_exercise_detail_screen.dart';
import '../../repositories/workout_plans_repository.dart';

/// WorkoutDetailScreen: Màn hình chi tiết kế hoạch tập luyện khi click vào WorkoutCard
/// Hiển thị danh sách các ngày tập của một kế hoạch tập luyện
class WorkoutDetailScreen extends StatefulWidget {
  final String planId; // now required for real data
  final String image;
  final String title;
  final String? subtitle;
  final String? description;
  const WorkoutDetailScreen({
    required this.planId,
    required this.image,
    required this.title,
    this.subtitle,
    this.description,
    super.key,
  });
  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  int? selectedExerciseIndex;
  final _repo = WorkoutPlansRepository();
  Future<List<WorkoutDayModel>>? _futureDays;
  List<WorkoutDayModel> _days = [];
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _futureDays = _fetchDays();
  }

  Future<List<WorkoutDayModel>> _fetchDays() async {
    try {
      final days = await _repo.getPlanDays(widget.planId);
      _days = days;
      if (_days.isNotEmpty) selectedExerciseIndex = 0;
      setState(() {});
      return days;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ngày tập (mock mode?): $e')),
        );
      }
      return [];
    }
  }

  Future<void> _addDay() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final nextNumber = _days.isEmpty
          ? 1
          : (_days
                    .where((d) => d.dayNumber != null)
                    .map((d) => d.dayNumber!)
                    .fold<int>(0, (p, c) => c > p ? c : p) +
                1);
      final created = await _repo.createDay(
        widget.planId,
        dayNumber: nextNumber,
        date: DateTime.now().add(Duration(days: nextNumber - 1)),
      );
      if (created != null) {
        _days.add(created);
        _days.sort((a, b) => (a.dayNumber ?? 0).compareTo(b.dayNumber ?? 0));
        selectedExerciseIndex = _days.length - 1;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tạo ngày: $e')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header với hình nền - chiều cao cố định
          SizedBox(
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
                  FutureBuilder<List<WorkoutDayModel>>(
                    future: _futureDays,
                    builder: (context, snapshot) {
                      final len = _days.length;
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$len ngày',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
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
                  if (_days.isNotEmpty) ...[
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
                                  '${_days.length} ngày tập',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_days.length} ngày (chưa có trạng thái)',
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
                              itemCount: _days.length,
                              itemBuilder: (context, index) {
                                final day = _days[index];
                                return WorkoutExerciseCard(
                                  exerciseNumber: index + 1,
                                  title: 'Ngày ${day.dayNumber ?? index + 1}',
                                  description: day.date != null
                                      ? 'Ngày ${day.date!.day}/${day.date!.month}'
                                      : 'Không có ngày',
                                  isActive:
                                      selectedExerciseIndex ==
                                      index, // Sử dụng selectedIndex
                                  isCompleted: false,
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
                      onPressed: _creating ? null : _addDay,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        _creating ? 'Đang tạo...' : 'Thêm ngày tập luyện',
                        style: const TextStyle(color: Colors.white),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedExerciseIndex != null &&
                              selectedExerciseIndex! < _days.length
                          ? () {
                              final idx = selectedExerciseIndex!;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WorkoutExerciseDetailScreen(
                                    workoutDayId: _days[idx].id,
                                    workoutPlanId: widget.planId,
                                    dayNumber: _days[idx].dayNumber ?? idx + 1,
                                    dayTitle:
                                        'Ngày ${_days[idx].dayNumber ?? idx + 1}',
                                    date: _getWorkoutDate(idx),
                                    calories: '200 calories',
                                    backgroundImage: widget.image,
                                  ),
                                ),
                              );
                            }
                          : null,
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
                        selectedExerciseIndex != null &&
                                selectedExerciseIndex! < _days.length
                            ? 'Bắt đầu Ngày ${_days[selectedExerciseIndex!].dayNumber ?? selectedExerciseIndex! + 1}'
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
