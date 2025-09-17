import 'package:flutter/material.dart';
import '../../widgets/exercise_card.dart';
import '../../repositories/workout_day_exercises_repository.dart';
import '../../repositories/exercises_repository.dart';
import 'exercise_detail_screen.dart';
import 'workout_session_screen.dart';
import 'add_exercise/select_muscle_group_screen.dart';

/// WorkoutExerciseDetailScreen: Màn hình chi tiết một ngày tập luyện
/// Hiển thị danh sách các bài tập trong một ngày tập cụ thể
class WorkoutExerciseDetailScreen extends StatefulWidget {
  final String workoutDayId; // Id của workout day để gọi API
  final String workoutPlanId; // Id của kế hoạch tập (cần cho tạo bài tập)
  final int dayNumber; // Số thứ tự ngày trong plan
  final String dayTitle; // Tên ngày tập (VD: "Buổi tập 1")
  final String date; // Ngày tháng năm (VD: "1/4/2025")
  final String calories; // Calories (VD: "200 calories")
  final String backgroundImage; // Hình nền

  const WorkoutExerciseDetailScreen({
    required this.workoutDayId,
    required this.workoutPlanId,
    required this.dayNumber,
    required this.dayTitle,
    required this.date,
    required this.calories,
    required this.backgroundImage,
    super.key,
  });

  @override
  State<WorkoutExerciseDetailScreen> createState() =>
      _WorkoutExerciseDetailScreenState();
}

class _WorkoutExerciseDetailScreenState
    extends State<WorkoutExerciseDetailScreen> {
  final _repo = WorkoutDayExercisesRepository();
  final _exerciseRepo = ExercisesRepository();
  bool _loading = true;
  String? _error;
  List<ExerciseItem> _exercises = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getByWorkoutDay(widget.workoutDayId);
      // Parallel fetch exercise details (with caching inside repository)
      final detailFutures = data.map((d) async {
        final detail = await _exerciseRepo.getById(d.exerciseId);
        return ExerciseItem(
          id: d.id, // record id dùng cho PATCH path
          exerciseId: d.exerciseId, // id bài tập gốc dùng fetch chi tiết
          name: detail?.name.isNotEmpty == true ? detail!.name : 'Exercise',
          reps: '${d.targetReps ?? detail?.defaultReps ?? 0}',
          sets: d.targetSets ?? detail?.defaultSets ?? 0,
          repsCount: d.targetReps ?? detail?.defaultReps ?? 0,
          weight: (d.targetWeight != null
              ? d.targetWeight!.toInt()
              : (detail?.defaultWeight ?? 0)),
          restTime: d.restTimeSec ?? detail?.restTime ?? 0,
          muscleGroupNames: detail?.muscleGroupNames ?? const [],
        );
      }).toList();
      final mapped = await Future.wait(detailFutures);
      if (mounted)
        setState(() {
          _exercises = mapped;
        });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header với hình nền và thông tin ngày tập
          SizedBox(
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
                        _loading
                            ? 'Đang tải...'
                            : _error != null
                            ? 'Lỗi'
                            : '${_exercises.length} bài tập',
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
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.pinkAccent,
                            ),
                          )
                        : _error != null
                        ? RefreshIndicator(
                            color: Colors.pinkAccent,
                            onRefresh: _fetch,
                            child: ListView(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    'Lỗi tải dữ liệu:\n$_error',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _fetch,
                                    child: const Text('Thử lại'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _exercises.isEmpty
                        ? RefreshIndicator(
                            color: Colors.pinkAccent,
                            onRefresh: _fetch,
                            child: ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'Chưa có bài tập',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.pinkAccent,
                            onRefresh: _fetch,
                            child: ListView.builder(
                              itemCount: _exercises.length,
                              itemBuilder: (context, index) {
                                final exercise = _exercises[index];
                                return ExerciseCard(
                                  exercise: exercise,
                                  index: index,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExerciseDetailScreen(
                                          // exerciseId phải là id bài tập gốc để fetch chi tiết & gửi trong body PATCH
                                          // record id (workout day exercise) đã truyền qua workoutDayExerciseId bên dưới
                                          exerciseId: exercise.exerciseId ?? '',
                                          workoutPlanId: widget.workoutPlanId,
                                          workoutDayId: widget.workoutDayId,
                                          workoutDayExerciseId: exercise
                                              .id, // record id chuẩn cho PATCH
                                          initialSets: exercise.sets > 0
                                              ? exercise.sets
                                              : 3,
                                          initialReps: exercise.repsCount > 0
                                              ? exercise.repsCount
                                              : 10,
                                          initialWeight: exercise.weight
                                              .toDouble(),
                                          initialRest: exercise.restTime,
                                          backgroundImage: exercise.image,
                                        ),
                                      ),
                                    );
                                    if (result is Map) {
                                      // Nếu detail trả về đã xoá bài tập
                                      if (result['deleted'] == true) {
                                        final deletedId =
                                            result['workoutDayExerciseId']
                                                as String?;
                                        if (deletedId != null) {
                                          setState(() {
                                            _exercises.removeWhere(
                                              (e) => e.id == deletedId,
                                            );
                                          });
                                        }
                                        return; // dừng, không cập nhật nữa
                                      }
                                      final sets =
                                          (result['sets'] as int?) ??
                                          exercise.sets;
                                      final reps =
                                          (result['reps'] as int?) ??
                                          exercise.repsCount;
                                      final weight =
                                          (result['weight'] as num?)?.toInt() ??
                                          exercise.weight;
                                      final rest =
                                          (result['rest'] as int?) ??
                                          exercise.restTime;
                                      setState(() {
                                        _exercises[index] = ExerciseItem(
                                          id: exercise.id,
                                          exerciseId: exercise.exerciseId,
                                          name: exercise.name,
                                          reps: '$reps',
                                          image: exercise.image,
                                          sets: sets,
                                          repsCount: reps,
                                          weight: weight,
                                          restTime: rest,
                                          muscleGroupNames:
                                              exercise.muscleGroupNames,
                                        );
                                      });
                                    }
                                  },
                                );
                              },
                            ),
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
                // Navigate tới WorkoutSessionScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutSessionScreen(
                      workoutTitle: widget.dayTitle,
                      exercises: _exercises,
                      currentExerciseIndex: 0,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
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
          onPressed: () async {
            if (widget.workoutPlanId.isEmpty ||
                widget.workoutPlanId == 'local') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không thể thêm bài tập ở chế độ local'),
                ),
              );
              return;
            }
            final created = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SelectMuscleGroupScreen(
                  workoutPlanId: widget.workoutPlanId,
                  workoutDayId: widget.workoutDayId,
                  dayNumber: widget.dayNumber,
                  excludedExerciseIds: _exercises
                      .map((e) => e.exerciseId)
                      .whereType<String>()
                      .toSet()
                      .toList(),
                ),
              ),
            );
            if (created != null) {
              _fetch();
            }
          },
          backgroundColor: const Color(0xFFFF6B6B),
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
