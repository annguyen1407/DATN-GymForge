import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/exercise_card.dart'; // For ExerciseItem model
import '../../services/exercise_logs_service.dart';
import '../../core/auth/token_manager.dart';
import 'widgets/exercise_list_sheet.dart';
import 'widgets/workout_completion_dialog.dart';
import '../../theme/design_tokens.dart';

/// WorkoutSessionScreen: Màn hình tập luyện chính
/// Hiển thị timer, thông tin hiệp, điều khiển phát nhạc và danh sách bài tập
class WorkoutSessionScreen extends StatefulWidget {
  final String workoutTitle;
  final List<ExerciseItem> exercises;
  final int currentExerciseIndex;
  final String workoutPlanId;
  final int dayNumber;
  final DateTime workoutDayDate;
  final String workoutDayId;

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
  Timer? _preCountdownTimer; // 3-second pre-start countdown

  late final AudioPlayer _countdownPlayer = AudioPlayer();

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
  int _preCountdownRemaining = 0;
  bool _isPreCountdown = false;
  // Internal: show weight/reps quick edit later (reserved)

  // Lưu trữ thông tin tập luyện
  Map<int, List<Map<String, dynamic>>> workoutData =
      {}; // exerciseIndex -> List of sets data

  @override
  void initState() {
    super.initState();
    currentExerciseIndex = widget.currentExerciseIndex;
    currentReps = widget.exercises[currentExerciseIndex].repsCount;
    currentWeight = widget.exercises[currentExerciseIndex].weight.round();
    _countdownPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _countdownPlayer.dispose();
    _workoutTimer?.cancel();
    _preCountdownTimer?.cancel();
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

  /// Hiển thị bottom sheet danh sách bài tập
  void _showExerciseListSheet() {
    showExerciseListSheet(
      context: context,
      exercises: widget.exercises,
      currentExerciseIndex: currentExerciseIndex,
      workoutData: workoutData,
    );
  }

  /// Dialog chỉnh sửa nhanh reps / weight của set đang chờ log
  void _showEditSetDialog() {
    if (!hasStarted || isResting || isPlaying || _isPreCountdown) return;

    final repsController = TextEditingController(text: currentReps.toString());
    final weightController = TextEditingController(
      text: currentWeight.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            // Tăng chiều cao tối thiểu để dễ thao tác nút Lưu
            constraints: BoxConstraints(
              minHeight:
                  media.size.height * 0.38, // cao hơn 1 xíu (~38% chiều cao)
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Chỉnh set',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Hiệp $currentSet/${_currentExercise.sets}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _CompactNumberField(
                        label: 'Reps',
                        controller: repsController,
                        min: 1,
                      ),
                    ),
                    if (!_isBodyweight) ...[
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CompactNumberField(
                          label: 'Kg',
                          controller: weightController,
                          min: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.text(
                        label: 'Đóng',
                        onPressed: () => Navigator.pop(ctx),
                        size: AppButtonSize.medium,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AppButton.primary(
                        label: 'Lưu',
                        onPressed: () {
                          final repsVal = int.tryParse(
                            repsController.text.trim(),
                          );
                          final weightVal = int.tryParse(
                            weightController.text.trim(),
                          );
                          setState(() {
                            if (repsVal != null && repsVal > 0) {
                              currentReps = repsVal;
                            }
                            if (!_isBodyweight && weightVal != null) {
                              if (weightVal >= 1) {
                                currentWeight = weightVal;
                              } else {
                                currentWeight = 1; // enforce min 1
                              }
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        size: AppButtonSize.medium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hiển thị dialog hoàn thành buổi tập và cho phép upload logs.
  void _showWorkoutCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép đóng bằng cách tap outside
      builder: (BuildContext context) {
        return WorkoutCompletionDialog(
          exercises: widget.exercises,
          workoutData: workoutData,
          isUploading: _isUploading,
          uploadStatus: _uploadStatus,
          // Sau khi lưu: pop ra thẳng trang workout_screen
          // Stack hiện tại (giả định): workout_screen -> workout_exercise_detail_screen -> workout_session_screen -> dialog
          // Cần pop: workout_session_screen & workout_exercise_detail_screen, sau đó dialog tự đóng.
          onComplete: () async {
            await _uploadExerciseLogs();
            if (!mounted) return;
            final nav = Navigator.of(context);
            // Pop workout_session_screen
            nav.pop();
            nav.pop();
            // Pop workout_exercise_detail_screen
            if (nav.canPop()) {
              nav.pop();
            }
          },
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
    if (isAutoMode) {
      // Thay vì start ngay -> countdown mới cho set tiếp theo
      _startPreCountdown();
    }
  }

  /// Điều khiển play/pause tùy theo trạng thái hiện tại (nghỉ / tập / chưa bắt đầu)
  void _togglePlayPause() {
    setState(() {
      if (_isPreCountdown) {
        // Huỷ countdown và bắt đầu ngay
        _preCountdownTimer?.cancel();
        _isPreCountdown = false;
        hasStarted = true;
        isPlaying = true;
        workoutTime = 0;
        _startTimer();
        return;
      }
      if (!hasStarted) {
        _startPreCountdown();
        return;
      }
      if (isResting) {
        if (isAutoMode) {
          return; // auto mode tự xử lý
        } else {
          // từ nghỉ manual -> countdown cho set kế
          _startPreCountdown();
          return;
        }
      }
      // đang tập -> pause/play
      isPlaying = !isPlaying;
      if (isPlaying) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  /// Khởi động đếm ngược 3 giây trước khi bắt đầu tập
  void _startPreCountdown() {
    setState(() {
      _isPreCountdown = true;
      _preCountdownRemaining = 3;
      isResting = false; // chuẩn bị vào set
      isPlaying = false;
    });
    _preCountdownTimer?.cancel();
    // Play combined 3-2-1-start audio; filename with spaces may cause issues => suggest rename.
    _countdownPlayer.stop();
    // Try original name, fallback suggestion rename.
    _countdownPlayer.play(AssetSource('sounds/beep 3-2-1-start.wav'));
    _preCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_preCountdownRemaining > 1) {
        setState(() => _preCountdownRemaining--);
      } else {
        t.cancel();
        setState(() {
          _isPreCountdown = false;
          hasStarted = true; // nếu đã rồi thì không sao
          isPlaying = true;
          workoutTime = 0;
        });
        _startTimer();
      }
    });
  }

  /// Hiển thị thời gian còn lại của đếm ngược
  String _getCountdownDisplay() {
    return _preCountdownRemaining.toString();
  }

  /// Định dạng thời gian mm:ss
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Lấy string hiển thị timer phù hợp với trạng thái.
  String _getTimerDisplay() {
    if (_isPreCountdown) {
      return _getCountdownDisplay(); // 3..2..1
    }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalH = constraints.maxHeight;
            final mediaHeight = _computeAdaptiveMediaHeight(totalH);
            return Stack(
              children: [
                Column(
                  children: [
                    _Header(
                      currentName: _currentExercise.name,
                      onBack: () => Navigator.pop(context),
                    ),
                    _ExerciseMedia(
                      imageUrl: _currentExercise.image,
                      forcedHeight: mediaHeight,
                      onShowList: _isPreCountdown
                          ? null
                          : _showExerciseListSheet,
                      disabled: _isPreCountdown,
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 6),
                    _QuickAdjustButton(
                      weight: currentWeight,
                      reps: currentReps,
                      isBodyweight: _isBodyweight,
                      enabled:
                          !isPlaying &&
                          hasStarted &&
                          !isResting &&
                          !_isPreCountdown,
                      onTap: _showEditSetDialog,
                    ),
                    const SizedBox(height: 10),
                    _CurrentStatsBar(
                      setLabel: 'Set $currentSet/${_currentExercise.sets}',
                      repsLabel: 'Reps $currentReps',
                      weightLabel: _isBodyweight
                          ? 'Bodyweight'
                          : '${currentWeight}kg',
                    ),
                    const SizedBox(height: 12),
                    // Control bar with ignore pointer when countdown active
                    IgnorePointer(
                      ignoring: _isPreCountdown,
                      child: Opacity(
                        opacity: _isPreCountdown ? 0.35 : 1,
                        child: _ControlBar(
                          hasStarted: hasStarted,
                          isResting: isResting,
                          isPlaying: isPlaying,
                          isAutoMode: isAutoMode,
                          onReplay10: (hasStarted && !isResting)
                              ? () => setState(() {
                                  workoutTime = (workoutTime - 10).clamp(
                                    0,
                                    workoutTime,
                                  );
                                })
                              : null,
                          onPrev: _previousExercise,
                          onNext: _nextExercise,
                          onTogglePlay:
                              (_isPreCountdown || (isResting && isAutoMode))
                              ? null
                              : _togglePlayPause,
                          onToggleAuto: _toggleAutoMode,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: _isPreCountdown,
                      child: Opacity(
                        opacity: _isPreCountdown ? 0.35 : 1,
                        child: _LargeLogButton(
                          enabled: hasStarted && !isResting && !_isPreCountdown,
                          isLastSet: currentSet >= _currentExercise.sets,
                          currentSet: currentSet,
                          onPressed: _logSet,
                          showDisabledHint: !hasStarted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                // Countdown overlay removed to keep digits vivid; interactivity already disabled per-control.
              ],
            );
          },
        ),
      ),
    );
  }

  double _computeAdaptiveMediaHeight(double totalHeight) {
    // Estimate heights of fixed sections below header (heuristic)
    const headerH = 60.0;
    const timerH = 110.0; // timer + info + spacing
    const quickAdjustH = 66.0;
    const statsH = 56.0;
    const controlsH = 110.0;
    const logH = 90.0;
    const spacing = 60.0; // sum of SizedBoxes
    final reserved =
        headerH + timerH + quickAdjustH + statsH + controlsH + logH + spacing;
    final remaining = totalHeight - reserved;
    // Desired range 40–50% of screen but must not cause overflow
    final target = totalHeight * 0.45;
    double h = remaining.clamp(140.0, target);
    // Additional clamp for very tall screens
    h = h.clamp(140.0, 420.0);
    return h;
  }

  void _previousExercise() {
    if (currentExerciseIndex == 0) return;
    setState(() {
      currentExerciseIndex--;
      currentSet = 1;
      workoutTime = 0;
      isResting = false;
      isPlaying = false;
      hasStarted = false; // require play again
      currentReps = widget.exercises[currentExerciseIndex].repsCount;
      currentWeight = widget.exercises[currentExerciseIndex].weight.round();
    });
    _stopTimer();
  }

  void _nextExercise() {
    if (currentExerciseIndex >= widget.exercises.length - 1) {
      _showWorkoutCompletedDialog();
      return;
    }
    setState(() {
      currentExerciseIndex++;
      currentSet = 1;
      workoutTime = 0;
      isResting = false;
      isPlaying = false;
      hasStarted = false;
      currentReps = widget.exercises[currentExerciseIndex].repsCount;
      currentWeight = widget.exercises[currentExerciseIndex].weight.round();
    });
    _stopTimer();
  }

  void _logSet() {
    if (!hasStarted || isResting || _isPreCountdown) return;
    final idx = currentExerciseIndex;
    // Safety clamps to ensure reps/weight adhere to >=1 (except bodyweight weight)
    if (currentReps < 1) currentReps = 1;
    if (!_isBodyweight && currentWeight < 1) currentWeight = 1;
    workoutData[idx] ??= [];
    workoutData[idx]!.add({
      'set': currentSet,
      'reps': currentReps,
      'weight': currentWeight,
      'time': workoutTime,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    final finished = currentSet >= _currentExercise.sets;
    if (finished) {
      _nextExercise();
      return;
    }
    setState(() {
      currentSet++;
      // reset reps to default của bài tập, giữ nguyên weight
      currentReps = _currentExercise.repsCount;
      isResting = true;
      isPlaying = false;
      workoutTime = 0;
      timeRemaining = _currentExercise.restTime;
    });
    if (isAutoMode) {
      _startTimer();
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center title
            Positioned.fill(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Text(
                    currentName,
                    key: ValueKey(currentName),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                    ),
                  ),
                ),
              ),
            ),
            // Back button on left
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
                tooltip: 'Quay lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseMedia extends StatelessWidget {
  final String imageUrl;
  final double? forcedHeight;
  final VoidCallback? onShowList; // new callback for list button
  final bool disabled; // disable interactions (countdown)
  const _ExerciseMedia({
    required this.imageUrl,
    this.forcedHeight,
    this.onShowList,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final mediaHeight = forcedHeight ?? (h < 720 ? 160.0 : 190.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: IgnorePointer(
        ignoring: disabled,
        child: Container(
          height: mediaHeight,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
            ),
            border: Border.all(color: Colors.white24, width: 0.6),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => _fallback(),
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    (progress.expectedTotalBytes ?? 1)
                              : null,
                          strokeWidth: 3,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    );
                  },
                )
              else
                _fallback(),
              // Fullscreen button
              Positioned(
                top: 8,
                right: 8,
                child: _PressableScale(
                  enabled: !disabled,
                  onTap: () {
                    if (imageUrl.isEmpty) return;
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.black,
                        insetPadding: const EdgeInsets.all(20),
                        child: InteractiveViewer(
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(imageUrl, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white30, width: 0.8),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // List button bottom-right
              if (onShowList != null)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: _PressableScale(
                    enabled: !disabled,
                    onTap: onShowList,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: const [
                            DesignTokens.brandGradientStart,
                            DesignTokens.brandGradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.list_alt, size: 16, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Danh sách',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.image_not_supported, color: Colors.white24, size: 42),
        SizedBox(height: 8),
        Text(
          'Không có media',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    ),
  );
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
            fontSize: 70,
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

class _QuickAdjustButton extends StatelessWidget {
  final int weight;
  final int reps;
  final bool isBodyweight;
  final bool enabled;
  final VoidCallback onTap;
  const _QuickAdjustButton({
    required this.weight,
    required this.reps,
    required this.isBodyweight,
    required this.enabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final label = isBodyweight
        ? 'Chỉnh reps ($reps)'
        : 'Chỉnh reps & tạ ($reps • ${weight}kg)';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? Colors.white12 : Colors.white10,
            foregroundColor: enabled ? Colors.orange : Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: enabled ? onTap : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _roundIcon(
            size: 52,
            child: IconButton(
              onPressed: onReplay10,
              icon: Icon(
                Icons.replay_10,
                color: (hasStarted && !isResting) ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 18),
          _roundIcon(
            size: 52,
            child: IconButton(
              onPressed: onPrev,
              icon: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: onTogglePlay,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: (isResting && isAutoMode)
                    ? LinearGradient(
                        colors: [Colors.grey[700]!, Colors.grey[600]!],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                (isResting && !isAutoMode)
                    ? Icons.play_arrow
                    : isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: 20),
          _roundIcon(
            size: 52,
            child: IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 18),
          _roundIcon(
            size: 52,
            color: isAutoMode ? Colors.green[900] : Colors.grey[800],
            child: IconButton(
              onPressed: onToggleAuto,
              icon: Text(
                'A',
                style: TextStyle(
                  color: isAutoMode ? Colors.greenAccent : Colors.grey,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({required Widget child, Color? color, double size = 40}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? Colors.grey[850],
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
}

class _LargeLogButton extends StatelessWidget {
  final bool enabled;
  final bool isLastSet;
  final int currentSet;
  final VoidCallback onPressed;
  final bool showDisabledHint;
  const _LargeLogButton({
    required this.enabled,
    required this.isLastSet,
    required this.currentSet,
    required this.onPressed,
    this.showDisabledHint = false,
  });
  @override
  Widget build(BuildContext context) {
    final label = isLastSet ? 'Hoàn thành bài tập' : 'Log set $currentSet';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: _PressableScale(
              enabled: enabled,
              onTap: enabled ? onPressed : null,
              child: AppButton.primary(
                label: label,
                onPressed: enabled ? onPressed : null,
                size: AppButtonSize.large,
              ),
            ),
          ),
          if (!enabled && showDisabledHint)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Bấm Play để bắt đầu hiệp đầu tiên',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// Removed inline collapsible list – replaced by bottom sheet list

class _CurrentStatsBar extends StatelessWidget {
  final String setLabel;
  final String repsLabel;
  final String weightLabel;
  const _CurrentStatsBar({
    required this.setLabel,
    required this.repsLabel,
    required this.weightLabel,
  });
  @override
  Widget build(BuildContext context) {
    Widget buildChip(String text, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: Center(child: buildChip(setLabel, Icons.repeat))),
          const SizedBox(width: 8),
          Expanded(
            child: Center(child: buildChip(repsLabel, Icons.fitness_center)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Center(child: buildChip(weightLabel, Icons.balance))),
        ],
      ),
    );
  }
}

// New adjustable number field with text input + +/- and presets
// Compact number field (simple input only)
class _CompactNumberField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final int min;
  const _CompactNumberField({
    required this.label,
    required this.controller,
    required this.min,
  });
  @override
  State<_CompactNumberField> createState() => _CompactNumberFieldState();
}

class _CompactNumberFieldState extends State<_CompactNumberField> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = int.tryParse(widget.controller.text) ?? widget.min;
    if (_value < widget.min) _value = widget.min;
    widget.controller.text = _value.toString();
  }

  void _set(int v) {
    if (v < widget.min) v = widget.min;
    setState(() {
      _value = v;
      widget.controller.text = _value.toString();
    });
  }

  void _inc() => _set(_value + 1);
  void _dec() => _set(_value - 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              _StepperButton(onTap: _dec, icon: Icons.remove, enabled: _value > widget.min),
              Expanded(
                child: Center(
                  child: Text(
                    _value.toString(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              _StepperButton(onTap: _inc, icon: Icons.add),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final VoidCallback onTap; 
  final IconData icon; 
  final bool enabled;
  const _StepperButton({
    required this.onTap,
    required this.icon,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: enabled ? Colors.white10 : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          width: 42,
          height: 48,
          child: Icon(icon, color: enabled ? Colors.orange : Colors.white30),
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  const _PressableScale({
    Key? key,
    required this.child,
    this.onTap,
    this.enabled = true,
  }) : super(key: key);
  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _down = false;
  static const _pressScale = .92;
  static const _duration = Duration(milliseconds: 120);
  void _set(bool v) {
    if (!widget.enabled) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final target = (_down && widget.enabled) ? _pressScale : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: target,
        duration: _duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
