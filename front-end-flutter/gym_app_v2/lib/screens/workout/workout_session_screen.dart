import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/exercise_card.dart';

/// WorkoutSessionScreen: Màn hình tập luyện chính
/// Hiển thị timer, thông tin hiệp, điều khiển phát nhạc và danh sách bài tập
class WorkoutSessionScreen extends StatefulWidget {
  final String workoutTitle; // Tên buổi tập
  final List<ExerciseItem> exercises; // Danh sách bài tập
  final int currentExerciseIndex; // Bài tập hiện tại

  const WorkoutSessionScreen({
    required this.workoutTitle,
    required this.exercises,
    this.currentExerciseIndex = 0,
    super.key,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _pulseController;
  Timer? _workoutTimer; // Thay thế AnimationController bằng Timer

  int currentExerciseIndex = 0;
  int currentSet = 1;
  int timeRemaining = 0; // Bắt đầu với 0, sẽ tính khi bắt đầu tập
  int workoutTime = 0; // Thời gian tập của hiệp hiện tại (đếm xuôi)
  int currentReps = 0; // Số reps thực tế của hiệp hiện tại
  bool isResting = false;
  bool isPlaying = false;
  bool hasStarted = false; // Chưa bắt đầu tập luyện
  bool isCompleted = false;
  bool isAutoMode = false; // Chế độ auto - chỉ đếm ngược khi bật

  // Lưu trữ thông tin tập luyện
  Map<int, List<Map<String, dynamic>>> workoutData =
      {}; // exerciseIndex -> List of sets data

  @override
  void initState() {
    super.initState();
    currentExerciseIndex = widget.currentExerciseIndex;
    currentReps =
        widget.exercises[currentExerciseIndex].repsCount; // Khởi tạo số reps

    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Không bắt đầu timer ngay, chờ user bấm play
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    _workoutTimer?.cancel(); // Hủy timer khi dispose
    super.dispose();
  }

  void _startTimer() {
    _workoutTimer?.cancel(); // Hủy timer cũ nếu có

    if (isResting && isAutoMode) {
      // Chế độ nghỉ + auto mode: đếm ngược mỗi giây
      _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && timeRemaining > 0) {
          setState(() {
            timeRemaining--;
          });
        } else if (timeRemaining == 0) {
          timer.cancel();
          _handleRestComplete();
        }
      });
    } else {
      // Chế độ tập hoặc nghỉ không auto: chỉ đếm xuôi
      _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && isPlaying && !isResting) {
          setState(() {
            workoutTime++;
          });
        }
      });
    }
  }

  void _stopTimer() {
    _workoutTimer?.cancel();
  }

  void _showRepsEditDialog() {
    if (!hasStarted || isResting || isPlaying) return;

    final TextEditingController repsController = TextEditingController(
      text: currentReps.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Chỉnh sửa số reps',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: repsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Số reps',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.purple),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.purple),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final newReps = int.tryParse(repsController.text);
                if (newReps != null && newReps > 0) {
                  setState(() {
                    currentReps = newReps;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.purple)),
            ),
          ],
        );
      },
    );
  }

  void _showWorkoutCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép đóng bằng cách tap outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Hoàn thành!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chúc mừng! Bạn đã hoàn thành buổi tập luyện.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thống kê tập luyện:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...workoutData.entries.map((entry) {
                  final exerciseIndex = entry.key;
                  final exerciseData = entry.value;
                  final exercise = widget.exercises[exerciseIndex];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...exerciseData.map((setData) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              'Hiệp ${setData['set']}: ${setData['reps']} reps, ${setData['weight']}kg, ${_formatTime(setData['time'])}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Lưu thông tin tập luyện (TODO: implement save to database)
                _saveWorkoutData();
                Navigator.pop(context); // Đóng dialog
                // Pop về MainScreen (giữ lại tab hiện tại)
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lưu và hoàn thành',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveWorkoutData() {
    // TODO: Implement save to database/API
    final workoutSummary = {
      'workoutTitle': widget.workoutTitle,
      'completedAt': DateTime.now(),
      'exercises': workoutData,
      'totalExercises': widget.exercises.length,
      'completedExercises': workoutData.length,
    };

    print('Saving workout data: $workoutSummary');
    // Ở đây sẽ call API để lưu dữ liệu vào backend
  }

  void _toggleAutoMode() {
    setState(() {
      isAutoMode = !isAutoMode;
      if (!isAutoMode && isResting) {
        // Tắt auto mode khi đang nghỉ -> dừng đếm ngược
        _stopTimer();
      } else if (isAutoMode && isResting) {
        // Bật auto mode khi đang nghỉ -> bắt đầu đếm ngược
        _startTimer();
      }
    });
  }

  void _handleRestComplete() {
    // Kết thúc nghỉ, bắt đầu hiệp mới (chỉ khi auto mode)
    if (isAutoMode) {
      setState(() {
        isResting = false;
        workoutTime = 0; // Reset thời gian tập
        isPlaying = true; // Tự động bắt đầu tập
      });
      _startTimer();
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (!hasStarted) {
        // Lần đầu bấm play - bắt đầu tập luyện
        hasStarted = true;
        isPlaying = true;
        workoutTime = 0;
        _startTimer();
      } else if (isResting) {
        if (isAutoMode) {
          // Đang nghỉ ở chế độ auto - KHÔNG cho phép bấm play
          // Timer đếm ngược sẽ tự động kết thúc và chuyển hiệp
          return; // Thoát khỏi function, không làm gì cả
        } else {
          // Đang nghỉ ở chế độ manual - kết thúc nghỉ và bắt đầu hiệp mới
          isResting = false;
          isPlaying = true;
          workoutTime = 0;
          _startTimer();
        }
      } else {
        // Tạm dừng/tiếp tục khi đang tập
        isPlaying = !isPlaying;
        if (isPlaying) {
          _startTimer();
        } else {
          _stopTimer();
        }
      }
    });
  }

  void _logSet() {
    final currentExercise = widget.exercises[currentExerciseIndex];

    // Lưu thông tin hiệp vào workoutData
    if (!workoutData.containsKey(currentExerciseIndex)) {
      workoutData[currentExerciseIndex] = [];
    }

    workoutData[currentExerciseIndex]!.add({
      'set': currentSet,
      'reps': currentReps,
      'time': workoutTime,
      'weight': currentExercise.weight,
      'timestamp': DateTime.now(),
    });

    print('Logged set $currentSet: ${workoutTime}s, $currentReps reps');

    if (currentSet < currentExercise.sets) {
      // Chuyển sang hiệp tiếp theo
      setState(() {
        currentSet++;
        isResting = true;
        if (isAutoMode) {
          timeRemaining = currentExercise.restTime;
          isPlaying = false; // Tạm dừng khi nghỉ
        }
        workoutTime = 0;
        // Reset currentReps về giá trị mặc định cho hiệp mới
        currentReps = currentExercise.repsCount;
      });
      _stopTimer();
      if (isAutoMode) {
        _startTimer(); // Bắt đầu đếm ngược nếu auto mode
      }
    } else {
      // Hoàn thành bài tập, chuyển sang bài tập tiếp theo
      _nextExercise();
    }
  }

  void _nextExercise() {
    if (currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        currentExerciseIndex++;
        currentSet = 1;
        isResting = false;
        workoutTime = 0;
        isPlaying = false; // Dừng lại khi chuyển bài tập mới
        hasStarted = false; // Reset trạng thái
        // Reset currentReps cho bài tập mới
        currentReps = widget.exercises[currentExerciseIndex].repsCount;
      });
      _stopTimer();
    } else {
      // Hoàn thành tất cả bài tập
      setState(() {
        isCompleted = true;
        isPlaying = false;
      });
      _stopTimer();
      _showWorkoutCompletedDialog();
    }
  }

  void _previousExercise() {
    if (currentExerciseIndex > 0) {
      setState(() {
        currentExerciseIndex--;
        currentSet = 1;
        isResting = false;
        workoutTime = 0;
        isPlaying = false; // Dừng lại khi chuyển bài tập mới
        hasStarted = false; // Reset trạng thái
        // Reset currentReps cho bài tập mới
        currentReps = widget.exercises[currentExerciseIndex].repsCount;
      });
      _stopTimer();
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getTimerDisplay() {
    if (!hasStarted) {
      return '0:00'; // Chưa bắt đầu
    }
    if (isResting && isAutoMode) {
      return _formatTime(timeRemaining); // Đếm ngược khi nghỉ + auto mode
    } else {
      return _formatTime(workoutTime); // Đếm xuôi khi tập hoặc nghỉ manual
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.exercises[currentExerciseIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header với tiêu đề và menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    currentExercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Hình ảnh bài tập - tạm thời màu đen
            Container(
              height: 130,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
            ),

            // Timer lớn
            Text(
              _getTimerDisplay(),
              style: TextStyle(
                color: (isResting && isAutoMode) ? Colors.orange : Colors.red,
                fontSize: 72,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(height: 8),

            // Thông tin hiệp
            Text(
              isResting
                  ? isAutoMode
                        ? 'Auto - Nghỉ ngơi: ${_formatTime(timeRemaining)} (Tự động tiếp tục)'
                        : 'Nghỉ ngơi - Bấm Play để tiếp tục'
                  : hasStarted
                  ? 'Hiệp $currentSet/${widget.exercises[currentExerciseIndex].sets}'
                  : 'Sẵn sàng - Bấm Play để bắt đầu',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Số tạ: ${currentExercise.weight} kg',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _showRepsEditDialog,
                    child: Row(
                      children: [
                        Text(
                          'Số rép: $currentReps',
                          style: TextStyle(
                            color: (!isPlaying && hasStarted && !isResting)
                                ? Colors.orange
                                : Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: (!isPlaying && hasStarted && !isResting)
                              ? Colors.orange
                              : Colors.orange,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Điều khiển - gọn hơn
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Replay 10s
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: hasStarted && !isResting
                        ? () {
                            setState(() {
                              workoutTime = (workoutTime - 10).clamp(
                                0,
                                workoutTime,
                              );
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.replay_10,
                      color: hasStarted && !isResting
                          ? Colors.white
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Previous
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _previousExercise,
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Play/Pause button - nhỏ hơn
                GestureDetector(
                  onTap: (isResting && isAutoMode) ? null : _togglePlayPause,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: (isResting && isAutoMode)
                          ? Colors.grey[600] // Màu xám khi không thể bấm
                          : Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      (isResting && !isAutoMode)
                          ? Icons.play_arrow
                          : isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Next
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _nextExercise,
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Auto button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAutoMode ? Colors.green[800] : Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _toggleAutoMode,
                    icon: Icon(
                      Icons.autorenew,
                      color: isAutoMode ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Log set button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 140),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasStarted && !isResting ? _logSet : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasStarted && !isResting
                        ? Colors.purple
                        : Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    currentSet < widget.exercises[currentExerciseIndex].sets
                        ? 'Log set $currentSet'
                        : 'Hoàn thành bài tập',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Workout list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Workout list',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = widget.exercises[index];
                        final isActive = index == currentExerciseIndex;
                        final isCompleted = index < currentExerciseIndex;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.orange
                                : isCompleted
                                ? Colors.grey[800]
                                : Colors.grey[900]?.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (isCompleted)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              if (isCompleted) const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${exercise.sets} hiệp',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.black54
                                            : Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (!isActive && !isCompleted)
                                const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
