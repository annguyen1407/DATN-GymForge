import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
// import '../../services/api_service.dart'; // replaced by repository abstraction
import '../../repositories/workout_plans_repository.dart';
import '../../widgets/day_actions_menu.dart';
import '../../widgets/add_action_button.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/destructive_confirm_sheet.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_button.dart';
import '../../repositories/workout_day_exercises_repository.dart';
import '../../repositories/exercises_repository.dart';
import 'exercise_detail_screen.dart';
import 'workout_session_screen.dart';
import 'add_exercise/select_muscle_group_screen.dart';
import '../../widgets/date/app_date_picker.dart';
import '../../utils/date_utils.dart';

/// Screen hiển thị chi tiết một ngày tập: danh sách bài tập, equipment cần thiết,
/// cùng menu hành động (sửa / xoá) ở góc phải trên.
class WorkoutExerciseDetailScreen extends StatefulWidget {
  final String workoutDayId;
  final String workoutPlanId;
  final int dayNumber;
  final String dayTitle;
  final String date;
  final String calories;
  final String backgroundImage;

  const WorkoutExerciseDetailScreen({
    super.key,
    required this.workoutDayId,
    required this.workoutPlanId,
    required this.dayNumber,
    required this.dayTitle,
    required this.date,
    required this.calories,
    required this.backgroundImage,
  });

  @override
  State<WorkoutExerciseDetailScreen> createState() =>
      _WorkoutExerciseDetailScreenState();
}

class _WorkoutExerciseDetailScreenState
    extends State<WorkoutExerciseDetailScreen> {
  final _repo = WorkoutDayExercisesRepository();
  final _exerciseRepo = ExercisesRepository();
  final _plansRepo = WorkoutPlansRepository();

  bool _loading = true;
  String? _error;
  List<ExerciseItem> _exercises = [];
  bool _preloadingGifs =
      false; // trạng thái preload media trước khi vào session
  double _preloadProgress = 0; // 0..1

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
      final relations = await _repo.getByWorkoutDay(widget.workoutDayId);
      final detailed = await Future.wait(
        relations.map((r) async {
          final ex = await _exerciseRepo.getById(r.exerciseId);
          return ExerciseItem(
            id: r.id,
            exerciseId: r.exerciseId,
            name: ex?.name.isNotEmpty == true ? ex!.name : 'Exercise',
            reps: '${r.targetReps ?? ex?.defaultReps ?? 0}',
            sets: r.targetSets ?? ex?.defaultSets ?? 0,
            repsCount: r.targetReps ?? ex?.defaultReps ?? 0,
            weight: r.targetWeight?.toInt() ?? ex?.defaultWeight ?? 0,
            restTime: r.restTimeSec ?? ex?.restTime ?? 0,
            muscleGroupNames: ex?.muscleGroupNames ?? const [],
            // image: giữ nguyên legacy (nếu sau này có thumbnail tĩnh) => hiện để rỗng
            image: '',
            gifUrl: ex?.gifUrl ?? '',
          );
        }),
      );
      if (!mounted) return;
      setState(() => _exercises = detailed);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleDayAction(DayAction action) async {
    switch (action) {
      case DayAction.edit:
        if (!mounted) return;
        // Trước đây chặn khi ngày là 'Chưa có ngày'. Giờ cho phép thiết lập luôn.
        final initial = _displayDate == 'Chưa có ngày'
            ? DateTime.now()
            : (AppDateUtils.parseIsoOrDisplay(_displayDate) ?? DateTime.now());
        final picked = await AppDatePicker.show(
          context,
          initialDate: initial,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          title: '',
          hideTitle: true,
          confirmLabel: 'Lưu',
          cancelLabel: 'Huỷ',
          disablePast: true,
        );
        if (!mounted) return;
        if (picked == null) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        final updated = await _plansRepo.updateDay(
          widget.workoutDayId,
          workoutPlanId: widget.workoutPlanId,
          date: picked,
        );
        if (!mounted) return;
        Navigator.pop(context);
        if (updated != null) {
          AppSnackBar.showSuccess(context, 'Đã cập nhật ngày tập');
          setState(() {
            _displayDate = AppDateUtils.formatDdMMyyyy(picked);
            _updatedDateIso = picked.toIso8601String();
          });
        } else {
          AppSnackBar.showError(context, 'Cập nhật thất bại');
        }
        break;
      case DayAction.delete:
        // Business rule: không cho xoá nếu vẫn còn bài tập trong ngày
        if (_exercises.isNotEmpty) {
          AppSnackBar.showWarning(
            context,
            'Không thể xoá: còn bài tập trong ngày. Hãy xoá hết bài tập trước.',
          );
          return;
        }
        final confirmed = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => DestructiveConfirmSheet(
            title: 'Xoá ngày tập',
            message:
                'Bạn chắc chắn muốn xoá ngày tập này? Hành động không thể hoàn tác.',
            confirmLabel: 'Xoá',
            onConfirm: () => Navigator.pop(ctx, true),
          ),
        );
        if (!mounted) return;
        if (confirmed != true) return;
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          final deleted = await _plansRepo.deleteDay(widget.workoutDayId);
          if (!mounted) return;
          Navigator.pop(context); // close loading dialog
          if (deleted != null) {
            AppSnackBar.showSuccess(context, 'Đã xoá ngày tập');
            Navigator.pop(context, {
              'deleted': true,
              'id': widget.workoutDayId,
            });
          } else {
            AppSnackBar.showError(context, 'Xoá thất bại, vui lòng thử lại.');
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // close loading
          final msg = e.toString();
          // Nếu API trả về 400 với message chuẩn, hiển thị thông báo thân thiện hơn.
          if (msg.contains('Cannot delete a day that has exercises')) {
            AppSnackBar.showWarning(
              context,
              'Không thể xoá ngày này vì vẫn còn bài tập. Hãy xoá các bài tập trước.',
            );
          } else {
            AppSnackBar.showError(context, 'Lỗi: $e');
          }
        }
        break;
    }
  }

  void _popWithResult() {
    final changed = _displayDate != _initialDate;
    Navigator.pop(
      context,
      changed
          ? {
              'updatedDate': _displayDate,
              if (_updatedDateIso != null && _displayDate != 'Chưa có ngày')
                'updatedDateIso': _updatedDateIso,
              'id': widget.workoutDayId,
            }
          : null,
    );
  }

  String? _updatedDateIso; // chỉ set khi người dùng cập nhật
  late String _displayDate = _initDisplay(widget.date);
  late final String _initialDate = _displayDate; // giữ lại để so sánh khi pop

  String _initDisplay(String raw) {
    // Một số workout day có thể chưa có date (null ở backend -> truyền xuống thành chuỗi rỗng hoặc 'null').
    // Trước đây fallback về ngày hiện tại gây hiểu lầm. Ta hiển thị placeholder thay vì ngày hôm nay.
    if (raw.trim().isEmpty || raw.toLowerCase() == 'null') {
      return 'Chưa có ngày';
    }
    final dt = AppDateUtils.parseIsoOrDisplay(raw);
    if (dt == null) {
      return 'Chưa có ngày';
    }
    return AppDateUtils.formatDdMMyyyy(dt);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _popWithResult();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildExercisesSection()),
            _buildStartButton(),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.backgroundImage.isNotEmpty
                ? Image.asset(
                    widget.backgroundImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientFallback(),
                  )
                : _gradientFallback(),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacityRatio(0.3),
                    Colors.black.withOpacityRatio(0.8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _popWithResult,
                ),
                DayActionsMenu(onAction: _handleDayAction),
              ],
            ),
          ),
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
                      _displayDate,
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
                const Text(
                  'You\'ll Need',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
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
    );
  }

  Widget _buildExercisesSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  )
                : _error != null
                ? _buildError()
                : _exercises.isEmpty
                ? _buildEmpty()
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
                                builder: (_) => ExerciseDetailScreen(
                                  exerciseId: exercise.exerciseId ?? '',
                                  workoutPlanId: widget.workoutPlanId,
                                  workoutDayId: widget.workoutDayId,
                                  workoutDayExerciseId: exercise.id,
                                  initialSets: exercise.sets > 0
                                      ? exercise.sets
                                      : 3,
                                  initialReps: exercise.repsCount > 0
                                      ? exercise.repsCount
                                      : 10,
                                  initialWeight: exercise.weight.toDouble(),
                                  initialRest: exercise.restTime,
                                  backgroundImage: exercise.image,
                                ),
                              ),
                            );
                            if (result is Map) {
                              if (result['deleted'] == true) {
                                final deletedId =
                                    result['workoutDayExerciseId'] as String?;
                                if (deletedId != null) {
                                  setState(() {
                                    _exercises.removeWhere(
                                      (e) => e.id == deletedId,
                                    );
                                  });
                                }
                                return;
                              }
                              final sets =
                                  (result['sets'] as int?) ?? exercise.sets;
                              final reps =
                                  (result['reps'] as int?) ??
                                  exercise.repsCount;
                              final weight =
                                  (result['weight'] as num?)?.toInt() ??
                                  exercise.weight;
                              final rest =
                                  (result['rest'] as int?) ?? exercise.restTime;
                              setState(() {
                                _exercises[index] = ExerciseItem(
                                  id: exercise.id,
                                  exerciseId: exercise.exerciseId,
                                  name: exercise.name,
                                  reps: '$reps',
                                  image: exercise.image,
                                  gifUrl: exercise.gifUrl,
                                  sets: sets,
                                  repsCount: reps,
                                  weight: weight,
                                  restTime: rest,
                                  muscleGroupNames: exercise.muscleGroupNames,
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
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      color: Colors.pinkAccent,
      onRefresh: _fetch,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'Lỗi tải dữ liệu:\n$_error',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: AppButton.outline(
              label: 'Thử lại',
              onPressed: _fetch,
              fullWidth: false,
              size: AppButtonSize.small,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
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
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: AppButton.gradient(
        label: _preloadingGifs
            ? 'Đang tải media ${((_preloadProgress * 100).clamp(0, 100)).toStringAsFixed(0)}%'
            : 'Khởi động bài tập',
        leadingIcon: Icons.play_arrow_rounded,
        onPressed: _exercises.isEmpty || _preloadingGifs
            ? null
            : () => _preloadGifsThenStart(),
      ),
    );
  }

  Future<void> _preloadGifsThenStart() async {
    final gifUrls = _exercises
        .map((e) => e.gifUrl)
        .where(
          (u) =>
              u.isNotEmpty &&
              (u.startsWith('http://') || u.startsWith('https://')),
        )
        .toList();
    if (gifUrls.isEmpty) {
      _navigateToSession();
      return;
    }
    setState(() {
      _preloadingGifs = true;
      _preloadProgress = 0;
    });
    int loaded = 0;
    for (final url in gifUrls) {
      if (!mounted) return;
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (_) {
        // ignore individual failures; still proceed
      } finally {
        loaded++;
        if (mounted) {
          setState(() {
            _preloadProgress = loaded / gifUrls.length;
          });
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _preloadingGifs = false;
    });
    _navigateToSession();
  }

  void _navigateToSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          workoutTitle: widget.dayTitle,
          exercises: _exercises,
          currentExerciseIndex: 0,
          workoutPlanId: widget.workoutPlanId,
          dayNumber: widget.dayNumber,
          workoutDayDate: _parseWorkoutDayDate(widget.date),
          workoutDayId: widget.workoutDayId,
        ),
      ),
    );
  }

  DateTime _parseWorkoutDayDate(String raw) {
    // raw có thể ISO hoặc dd/MM/yyyy (đang hiển thị). Reuse AppDateUtils nếu cần.
    final parsed = AppDateUtils.parseIsoOrDisplay(raw) ?? DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: AddActionButton.circle(
        onPressed: () async {
          if (widget.workoutPlanId.isEmpty || widget.workoutPlanId == 'local') {
            AppSnackBar.showWarning(
              context,
              'Không thể thêm bài tập ở chế độ local',
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
      ),
    );
  }

  Widget _buildEquipmentItem(String name, IconData icon) {
    return Container(
      width: 120,
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacityRatio(0.6),
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

  Widget _gradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple[400]!, Colors.purple[800]!],
        ),
      ),
    );
  }
}
