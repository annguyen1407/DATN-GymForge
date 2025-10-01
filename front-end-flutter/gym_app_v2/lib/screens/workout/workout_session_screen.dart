import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
import 'dart:async';
import '../../widgets/app_button.dart';
import '../../widgets/exercise_card.dart';
import '../../utils/workout_completion.dart';
import '../../services/exercise_logs_service.dart';
import '../../core/auth/token_manager.dart';
import '../../core/logging/app_logger.dart';

/// WorkoutSessionScreen: Màn hình tập luyện chính
/// Hiển thị timer, thông tin hiệp, điều khiển phát nhạc và danh sách bài tập
class WorkoutSessionScreen extends StatefulWidget {
  final String workoutTitle; // Tên buổi tập
  final List<ExerciseItem> exercises; // Danh sách bài tập
  final int currentExerciseIndex; // Bài tập hiện tại
  final String workoutPlanId; // Plan id để log
  final int dayNumber; // Số ngày trong plan
  final DateTime workoutDayDate; // ngày thực tế của workout day
  final String workoutDayId; // id của workout day để log chính xác

  const WorkoutSessionScreen({
    required this.workoutTitle,
    required this.exercises,
    this.currentExerciseIndex = 0,
    required this.workoutPlanId,
    required this.dayNumber,
    required this.workoutDayDate,
    required this.workoutDayId,
    super.key,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  static const int kUploadStatusThrottle =
      2; // chỉ cập nhật trạng thái mỗi 2 log
  // Chỉ còn sử dụng Timer đơn giản thay vì AnimationController cho hiệu năng & đơn giản.
  Timer? _workoutTimer; // Timer chính cho hiệp tập hoặc thời gian nghỉ

  int currentExerciseIndex = 0;
  int currentSet = 1;
  int timeRemaining = 0; // Bắt đầu với 0, sẽ tính khi bắt đầu tập
  int workoutTime = 0; // Thời gian tập của hiệp hiện tại (đếm xuôi)
  int currentReps = 0; // Số reps thực tế của hiệp hiện tại
  int currentWeight = 0; // Trọng lượng tạ (kg) dạng số nguyên
  bool isResting = false;
  bool isPlaying = false;
  bool hasStarted = false; // Chưa bắt đầu tập luyện
  bool isAutoMode = false; // Chế độ auto - chỉ đếm ngược khi bật
  bool _isUploading = false; // trạng thái upload logs
  String _uploadStatus = '';

  // Lưu trữ thông tin tập luyện
  Map<int, List<Map<String, dynamic>>> workoutData =
      {}; // exerciseIndex -> List of sets data

  @override
  void initState() {
    super.initState();
    currentExerciseIndex = widget.currentExerciseIndex;
    currentReps = widget.exercises[currentExerciseIndex].repsCount;
    currentWeight = widget.exercises[currentExerciseIndex].weight.round();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    super.dispose();
  }

  /// Getter tiện lợi lấy bài tập hiện tại.
  ExerciseItem get _currentExercise => widget.exercises[currentExerciseIndex];
  bool get _isBodyweight =>
      _currentExercise.weight.round() == 0; // bài tập không dùng tạ

  /// Khởi động timer theo trạng thái hiện tại (nghỉ auto -> đếm ngược, tập -> đếm xuôi)
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

  /// Dừng timer hiện tại (nếu có)
  void _stopTimer() {
    _workoutTimer?.cancel();
  }

  /// Dialog chỉnh sửa nhanh reps / weight của set đang chờ log
  void _showEditSetDialog() {
    if (!hasStarted || isResting || isPlaying) return;

    final TextEditingController repsController = TextEditingController(
      text: currentReps.toString(),
    );
    final TextEditingController weightController = TextEditingController(
      text: currentWeight.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Chỉnh sửa set',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
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
              if (!_isBodyweight) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Trọng lượng (kg)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                    ),
                  ),
                ),
              ],
              // Bodyweight: không hiển thị field weight và cũng không cần note
            ],
          ),
          actions: [
            AppButton.text(
              label: 'Hủy',
              onPressed: () => Navigator.pop(context),
              fullWidth: false,
              size: AppButtonSize.small,
            ),
            AppButton.primary(
              label: 'Lưu',
              onPressed: () {
                final newReps = int.tryParse(repsController.text);
                final newWeight = int.tryParse(weightController.text);
                setState(() {
                  if (newReps != null && newReps > 0) {
                    currentReps = newReps;
                  }
                  if (!_isBodyweight && newWeight != null && newWeight >= 0) {
                    currentWeight = newWeight;
                  }
                });
                Navigator.pop(context);
              },
              size: AppButtonSize.small,
              fullWidth: false,
            ),
          ],
        );
      },
    );
  }

  /// Hiển thị dialog hoàn thành buổi tập và cho phép upload logs.
  void _showWorkoutCompletedDialog() {
    // Tính % hoàn thành trước khi hiển thị dialog
    final completion = computeWorkoutCompletion(
      plannedExercises: widget.exercises,
      workoutData: workoutData,
      params: const WorkoutCompletionCalculatorParams(
        repValue: 1, // có thể chỉnh theo bodyweight user trong tương lai
        allowOver100: false,
        maxIntensityMultiplier: 1.2,
        hybridAlpha: 0.8,
      ),
    );

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
                const SizedBox(height: 12),
                // Summary metrics
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tỉ lệ hoàn thành: ${completion.hybridPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Volume: ${completion.volumePercent.toStringAsFixed(1)}% | Sets: ${completion.setsPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Load đạt được: ${completion.achievedLoad.toStringAsFixed(1)} / ${completion.targetLoad.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sets: ${completion.totalSetsDone}/${completion.totalSetsPlanned}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _uploadStatus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            AppButton.primary(
              label: _isUploading ? 'Đang lưu...' : 'Lưu và hoàn thành',
              size: AppButtonSize.medium,
              fullWidth: false,
              onPressed: _isUploading
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      await _uploadExerciseLogs();
                      if (!mounted) return;
                      navigator.pop(); // close dialog
                      if (!mounted) return;
                      navigator.popUntil((route) => route.isFirst);
                    },
            ),
          ],
        );
      },
    );
  }

  /// Upload toàn bộ exercise logs từng bài (hiện serialize tối giản để tương thích backend).
  Future<void> _uploadExerciseLogs() async {
    // Guard: cần workoutPlanId & dayNumber
    final planId = widget.workoutPlanId;
    final dayNum = widget.dayNumber;

    // Chỉ upload những bài thực sự có log (user đã hoàn thành ít nhất 1 set).
    // Điều này cho phép user "skip" bài tập bằng cách bấm Next mà không log set nào.
    final loggedExerciseIndices = workoutData.keys.toSet();
    final loggedExercises = <ExerciseItem>[];
    for (int i = 0; i < widget.exercises.length; i++) {
      if (loggedExerciseIndices.contains(i) &&
          (workoutData[i]?.isNotEmpty ?? false)) {
        loggedExercises.add(widget.exercises[i]);
      }
    }

    if (loggedExercises.isEmpty) {
      // Không có gì để upload -> thông báo và thoát
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có bài tập nào được log.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Validate id chỉ trên các bài có log (bỏ qua bài skip).
    final missingIds = loggedExercises
        .where((e) => (e.id == null || e.id!.isEmpty))
        .toList();
    if (missingIds.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Một số bài tập chưa có workoutExerciseId - không thể gửi log.',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      debugPrint(
        '[ExerciseLogs] Abort upload: missing workoutExerciseId for ${missingIds.length} logged exercises',
      );
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Bắt đầu gửi logs...';
    });

    try {
      final userId = await TokenManager.instance.getCurrentUserId();
      final payloads = await ExerciseLogsService.instance.buildPayloads(
        // Chỉ truyền vào những bài có log
        exercises: loggedExercises,
        workoutData: workoutData,
        workoutPlanId: planId,
        dayNumber: dayNum,
        workoutDayDate: widget.workoutDayDate,
        workoutDayId: widget.workoutDayId,
        userId: userId,
      );
      int success = 0;
      int failed = 0;
      for (int i = 0; i < payloads.length; i++) {
        final p = payloads[i];
        // Cập nhật status thưa hơn để tránh re-build quá nhiều nếu danh sách dài
        if (i == 0 ||
            i == payloads.length - 1 ||
            i % kUploadStatusThrottle == 0) {
          if (mounted) {
            setState(() {
              _uploadStatus =
                  'Đang gửi ${i + 1}/${payloads.length}: ${p.exerciseName}';
            });
          }
        }
        final res = await ExerciseLogsService.instance.createLog(p);
        if (res.status >= 200 && res.status < 300 && res.error == null) {
          success++;
        } else {
          debugPrint(
            '[ExerciseLogs] Failed for ${p.exerciseName}: ${res.message}',
          );
          failed++;
        }
      }
      setState(() {
        _uploadStatus = 'Hoàn tất $success/${payloads.length}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gửi log: thành công $success, thất bại $failed',
              style: const TextStyle(fontSize: 14),
            ),
            backgroundColor: failed == 0
                ? Colors.green[600]
                : Colors.orange[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ExerciseLogs] Exception: $e');
    } finally {
      // Trì hoãn 300ms để user thấy trạng thái cuối
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Bật / tắt chế độ tự động: khi nghỉ sẽ đếm ngược và tự chuyển hiệp.
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

  /// Gọi khi thời gian nghỉ auto kết thúc -> bắt đầu hiệp mới.
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

  /// Điều khiển play/pause tùy theo trạng thái hiện tại (nghỉ / tập / chưa bắt đầu)
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

  /// Ghi lại 1 set đã hoàn thành cho bài tập hiện tại.
  void _logSet() {
    final currentExercise = _currentExercise;

    // Lưu thông tin hiệp vào workoutData
    if (!workoutData.containsKey(currentExerciseIndex)) {
      workoutData[currentExerciseIndex] = [];
    }

    workoutData[currentExerciseIndex]!.add({
      'set': currentSet,
      'reps': currentReps,
      'time': workoutTime,
      'weight': currentWeight,
      'timestamp': DateTime.now(),
    });

    AppLogger.debug(
      'Logged set $currentSet: ${workoutTime}s, $currentReps reps',
      tag: 'WorkoutSession',
    );

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

  /// Chuyển sang bài tập tiếp theo hoặc kết thúc toàn bộ buổi.
  void _nextExercise() {
    if (currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        currentExerciseIndex++;
        currentSet = 1;
        isResting = false;
        workoutTime = 0;
        isPlaying = false; // Dừng lại khi chuyển bài tập mới
        hasStarted = false; // Reset trạng thái
        // Reset currentReps & weight cho bài tập mới
        currentReps = widget.exercises[currentExerciseIndex].repsCount;
        currentWeight = widget.exercises[currentExerciseIndex].weight.round();
      });
      _stopTimer();
    } else {
      // Hoàn thành tất cả bài tập
      setState(() {
        isPlaying = false;
      });
      _stopTimer();
      _showWorkoutCompletedDialog();
    }
  }

  /// Quay lại bài tập trước đó (nếu có)
  void _previousExercise() {
    if (currentExerciseIndex > 0) {
      setState(() {
        currentExerciseIndex--;
        currentSet = 1;
        isResting = false;
        workoutTime = 0;
        isPlaying = false; // Dừng lại khi chuyển bài tập mới
        hasStarted = false; // Reset trạng thái
        // Reset currentReps & weight cho bài tập trước
        currentReps = widget.exercises[currentExerciseIndex].repsCount;
        currentWeight = widget.exercises[currentExerciseIndex].weight.round();
      });
      _stopTimer();
    }
  }

  /// Định dạng thời gian mm:ss
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Lấy string hiển thị timer phù hợp với trạng thái.
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              currentName: _currentExercise.name,
              onBack: () => Navigator.pop(context),
            ),
            _ExerciseImagePlaceholder(),
            _TimerPanel(
              display: _getTimerDisplay(),
              isResting: isResting,
              isAutoMode: isAutoMode,
              infoText: isResting
                  ? isAutoMode
                        ? 'Auto - Nghỉ ngơi: ${_formatTime(timeRemaining)} (Tự động tiếp tục)'
                        : 'Nghỉ ngơi - Bấm Play để tiếp tục'
                  : hasStarted
                  ? 'Hiệp $currentSet/${_currentExercise.sets}'
                  : 'Sẵn sàng - Bấm Play để bắt đầu',
            ),
            _ExerciseMetaBar(
              currentWeight: currentWeight,
              currentReps: currentReps,
              canEdit: !isPlaying && hasStarted && !isResting,
              onEdit: _showEditSetDialog,
              isBodyweight: _isBodyweight,
            ),
            _ControlBar(
              hasStarted: hasStarted,
              isResting: isResting,
              isPlaying: isPlaying,
              isAutoMode: isAutoMode,
              onReplay10: (hasStarted && !isResting)
                  ? () => setState(() {
                      workoutTime = (workoutTime - 10).clamp(0, workoutTime);
                    })
                  : null,
              onPrev: _previousExercise,
              onNext: _nextExercise,
              onTogglePlay: (isResting && isAutoMode) ? null : _togglePlayPause,
              onToggleAuto: _toggleAutoMode,
            ),
            _LogSetButton(
              enabled: hasStarted && !isResting,
              isLastSet: currentSet >= _currentExercise.sets,
              currentSet: currentSet,
              onPressed: _logSet,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _WorkoutList(
                exercises: widget.exercises,
                currentExerciseIndex: currentExerciseIndex,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- Extracted UI components ---

class _Header extends StatelessWidget {
  final String currentName;
  final VoidCallback onBack;
  const _Header({required this.currentName, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              currentName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ExerciseImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  final String display;
  final bool isResting;
  final bool isAutoMode;
  final String infoText;
  const _TimerPanel({
    required this.display,
    required this.isResting,
    required this.isAutoMode,
    required this.infoText,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          display,
          style: TextStyle(
            color: (isResting && isAutoMode) ? Colors.orange : Colors.red,
            fontSize: 72,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          infoText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ExerciseMetaBar extends StatelessWidget {
  final int currentWeight;
  final int currentReps;
  final bool canEdit;
  final VoidCallback onEdit;
  final bool isBodyweight;
  const _ExerciseMetaBar({
    required this.currentWeight,
    required this.currentReps,
    required this.canEdit,
    required this.onEdit,
    required this.isBodyweight,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isBodyweight)
            GestureDetector(
              onTap: (canEdit && !isBodyweight) ? onEdit : null,
              child: Text(
                'Số tạ: $currentWeight kg',
                style: TextStyle(
                  color: (canEdit && !isBodyweight)
                      ? Colors.orange
                      : Colors.white70,
                  fontSize: 14,
                ),
              ),
            )
          else
            const SizedBox(width: 0), // giữ layout cân đối
          GestureDetector(
            onTap: canEdit ? onEdit : null,
            child: Row(
              children: [
                Text(
                  'Số rép: $currentReps',
                  style: TextStyle(
                    color: canEdit ? Colors.orange : Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.orange, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final bool hasStarted;
  final bool isResting;
  final bool isPlaying;
  final bool isAutoMode;
  final VoidCallback? onReplay10;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onTogglePlay;
  final VoidCallback onToggleAuto;
  const _ControlBar({
    required this.hasStarted,
    required this.isResting,
    required this.isPlaying,
    required this.isAutoMode,
    required this.onReplay10,
    required this.onPrev,
    required this.onNext,
    required this.onTogglePlay,
    required this.onToggleAuto,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _roundIcon(
            child: IconButton(
              onPressed: onReplay10,
              icon: Icon(
                Icons.replay_10,
                color: (hasStarted && !isResting) ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _roundIcon(
            child: IconButton(
              onPressed: onPrev,
              icon: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onTogglePlay,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (isResting && isAutoMode)
                    ? Colors.grey[600]
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
          _roundIcon(
            child: IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          _roundIcon(
            color: isAutoMode ? Colors.green[800] : Colors.grey[800],
            child: IconButton(
              onPressed: onToggleAuto,
              icon: Icon(
                Icons.autorenew,
                color: isAutoMode ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({required Widget child, Color? color}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _LogSetButton extends StatelessWidget {
  final bool enabled;
  final bool isLastSet;
  final int currentSet;
  final VoidCallback onPressed;
  const _LogSetButton({
    required this.enabled,
    required this.isLastSet,
    required this.currentSet,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 140, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: AppButton.primary(
          label: isLastSet ? 'Hoàn thành bài tập' : 'Log set $currentSet',
          onPressed: enabled ? onPressed : null,
          size: AppButtonSize.large,
        ),
      ),
    );
  }
}

class _WorkoutList extends StatelessWidget {
  final List<ExerciseItem> exercises;
  final int currentExerciseIndex;
  const _WorkoutList({
    required this.exercises,
    required this.currentExerciseIndex,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Workout list',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
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
                      : Colors.grey[900]?.withOpacityRatio(0.5),
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
                              color: isActive ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${exercise.sets} hiệp',
                            style: TextStyle(
                              color: isActive ? Colors.black54 : Colors.white70,
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
    );
  }
}
