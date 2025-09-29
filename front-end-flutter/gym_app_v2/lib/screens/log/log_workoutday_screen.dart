import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'log_exercise_detail_screen.dart';
import '../../repositories/exercises_repository.dart';
import '../../repositories/workout_day_exercises_repository.dart';
import '../../models/exercise_model.dart';

/// WorkoutLogScreen: Displays details of a workout plan/day log including exercises and completion gauges
class WorkoutLogScreen extends StatefulWidget {
  final String planName;
  final List<Map<String, dynamic>> exercises; // raw logs items from API
  final String? workoutDayId; // để fetch danh sách bài tập theo kế hoạch
  const WorkoutLogScreen({
    required this.planName,
    required this.exercises,
    this.workoutDayId,
    super.key,
  });

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen>
    with SingleTickerProviderStateMixin {
  // ===== Design Tokens / Theme Helpers =====
  static const _accent = Color(0xFF8854FF);
  static const _bg = Colors.black;
  static const _cardBase = Color(0xFF121214);
  static const _cardBorder = Color(0xFF262626);
  static const _cardElevated = Color(0xFF1A1A1D);
  // Semantic colors (soft ramp for chips & progress states)
  static const _success = Color(0xFF41C27A); // Completed
  static const _medium = Color(0xFFE6C04C); // Mid progress
  static const _low = Color(0xFFEF7D55); // Low progress
  static const _veryLow = Color(0xFFDC4E55); // Very low / almost none

  late final AnimationController _shimmerCtrl;
  final _exerciseRepo = ExercisesRepository();
  final Map<String, ExerciseModel?> _exerciseCache = {}; // exerciseId->model
  bool _loadingNames = true;
  bool _loggedMissingOnce = false; // tránh spam log
  static const bool _verboseMissingIdLog = false; // đặt true nếu cần soi kỹ
  final _workoutDayExercisesRepo = WorkoutDayExercisesRepository();
  Set<String>? _plannedExerciseIds; // exerciseId theo kế hoạch (distinct)
  bool _loadingPlanned = false;
  final Set<String> _expanded = {}; // exerciseIds đang mở rộng

  Map<String, List<Map<String, dynamic>>> get _groupedLogs {
    final Map<String, List<Map<String, dynamic>>> g = {};
    for (final raw in widget.exercises) {
      final id =
          _extractExerciseId(raw) ?? '__missing__${raw['id'] ?? UniqueKey()}';
      g.putIfAbsent(id, () => []).add(raw);
    }
    return g;
  }

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _prefetchExerciseNames();
    _loadPlannedExercises();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlannedExercises() async {
    final dayId = widget.workoutDayId;
    if (dayId == null || dayId.isEmpty) return;
    setState(() => _loadingPlanned = true);
    try {
      final list = await _workoutDayExercisesRepo.getByWorkoutDay(dayId);
      final ids = <String>{};
      for (final dto in list) {
        ids.add(dto.exerciseId);
      }
      if (mounted) setState(() => _plannedExerciseIds = ids);
    } catch (e) {
      debugPrint('[WorkoutLogScreen] Lỗi fetch planned exercises: $e');
    } finally {
      if (mounted) setState(() => _loadingPlanned = false);
    }
  }

  double _averageProgress() {
    // Gom progress theo exerciseId (nhiều log cùng exercise cộng dồn, cap 1.0)
    final Map<String, double> acc = {};
    final Set<String> loggedIds = {};
    for (final raw in widget.exercises) {
      final exId = _extractExerciseId(raw);
      if (exId == null) continue;
      final p = _resolveProgress(raw); // 0..1
      acc[exId] = (acc[exId] ?? 0) + p;
      loggedIds.add(exId);
    }
    if (acc.isEmpty) return 0.0;
    // Cap từng exercise <=1.0
    acc.updateAll((key, value) => value > 1.0 ? 1.0 : value);

    List<String> denominatorSet;
    if (_plannedExerciseIds != null && _plannedExerciseIds!.isNotEmpty) {
      denominatorSet = _plannedExerciseIds!.toList();
      // Tìm bài tập nào thiếu (có trong kế hoạch nhưng chưa log)
      _missingExerciseCount = denominatorSet
          .where((id) => !loggedIds.contains(id))
          .length;
    } else {
      // fallback: distinct exerciseIds thực tế
      denominatorSet = acc.keys.toList();
      _missingExerciseCount = 0;
    }
    if (denominatorSet.isEmpty) return 0.0;

    double sum = 0;
    for (final exId in denominatorSet) {
      sum += acc[exId] ?? 0.0; // nếu chưa log => 0
    }
    final avg = sum / denominatorSet.length; // đã ở range 0..1
    return avg.clamp(0.0, 1.0);
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds == 0) return '0 giây';

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes > 0) {
      if (seconds > 0) {
        return '$minutes phút $seconds giây';
      }
      return '$minutes phút';
    }
    return '$seconds giây';

    return '${seconds}s';
  }

  int _calculateTotalTime() {
    int total = 0;
    for (final e in widget.exercises) {
      // Debug: in ra toàn bộ object để kiểm tra
      debugPrint('[Time Debug] Raw exercise log: $e');

      // Lấy totalTime trực tiếp từ root level của log
      final time = e['totalTime'];
      if (time is num) {
        total += time.toInt();
        debugPrint('[Time Debug] Found time: $time');
      } else {
        debugPrint('[Time Debug] WARNING: No valid time found in log');
      }
    }
    debugPrint('[Time Debug] Total time calculated: $total seconds');
    return total;
  }

  int _missingExerciseCount =
      0; // số bài tập thiếu (trong kế hoạch nhưng chưa log)

  String? _extractExerciseId(Map<String, dynamic> e) {
    try {
      if (e['workoutExercise'] is Map) {
        final nested = e['workoutExercise'] as Map;
        // Chỉ lấy exerciseId từ workoutExercise, đây là ID thật của bài tập
        final exerciseId = nested['exerciseId'];
        if (exerciseId is String && exerciseId.isNotEmpty) {
          debugPrint(
            '[WorkoutLogScreen] Tìm thấy exerciseId=$exerciseId để fetch',
          );
          return exerciseId;
        }
      }
    } catch (_) {}
    debugPrint(
      '[WorkoutLogScreen] WARN: Không tìm thấy workoutExercise.exerciseId trong item',
    );
    return null;
  }

  Future<void> _prefetchExerciseNames() async {
    // Luôn cố gắng fetch tên bài tập chuẩn từ API dựa vào workoutExercise.exerciseId
    if (!_loadingNames) setState(() => _loadingNames = true);

    final ids = <String>{};
    for (final raw in widget.exercises) {
      final exId = _extractExerciseId(raw);
      if (exId != null && !_exerciseCache.containsKey(exId)) {
        ids.add(exId);
      }
      if (exId == null && !_loggedMissingOnce && _verboseMissingIdLog) {
        _loggedMissingOnce = true;
        debugPrint(
          '[WorkoutLogScreen] Không tìm thấy exerciseId trong item keys=${raw.keys.toList()}',
        );
      }
    }

    if (ids.isEmpty) {
      if (mounted) setState(() => _loadingNames = false);
      return;
    }

    // Fetch đồng thời để nhanh hơn
    await Future.wait(
      ids.map((id) async {
        try {
          final model = await _exerciseRepo.getById(id);
          _exerciseCache[id] = model;
        } catch (_) {
          _exerciseCache[id] = null; // đánh dấu đã thử
        }
      }),
    );

    if (mounted) setState(() => _loadingNames = false);
  }

  String _resolveExerciseName(Map<String, dynamic> raw) {
    // Ưu tiên tên chuẩn lấy từ API (model) nếu đã có trong cache.
    // Nếu chưa có model nhưng có tên thô thì hiển thị tạm; khi fetch xong sẽ rebuild.
    // Trong lúc đang tải và chưa có gì: 'Đang tải…'. Hết tải mà vẫn không có -> fallback chung.
    try {
      final exId = _extractExerciseId(raw);
      if (exId != null) {
        final model = _exerciseCache[exId];
        if (model != null && model.name.trim().isNotEmpty) {
          return model.name.trim();
        }
        // Chưa có model: dùng tên thô tạm (nếu có)
        for (final key in ['name', 'exerciseName']) {
          final v = raw[key];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return _loadingNames ? 'Đang tải…' : 'Exercise $exId';
      }
      // Không có id => thử tên thô
      for (final key in ['name', 'exerciseName']) {
        final v = raw[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    } catch (_) {}
    return _loadingNames ? 'Đang tải…' : 'Bài tập';
  }

  double _resolveProgress(Map<String, dynamic> e) {
    // Accept keys: 'progress' (0..1), 'progressPercent' (0..100 or 0..1), default 0.
    dynamic raw = e['progress'];
    raw ??= e['progressPercent'];
    if (raw is num) {
      double v = raw.toDouble();
      if (v > 1.0) v = v / 100.0; // treat as percent
      if (v < 0) v = 0;
      if (v > 1) v = 1;
      return v;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final avg = _averageProgress();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text(
          widget.planName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_loadingNames || _loadingPlanned)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: widget.exercises.isEmpty
              ? const Center(
                  child: Text(
                    'Không có bài tập',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _prefetchExerciseNames(),
                  color: _accent,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _headerCard(avg)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Text(
                            'Danh sách bài tập',
                            style: TextStyle(
                              color: Colors.white.withOpacity(.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                      ),
                      if (_loadingNames || _loadingPlanned) _buildShimmerList(),
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 4),
                        sliver: _groupedExerciseList(),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _headerCard(double avg) {
    final percentLabel = '${(avg * 100).toStringAsFixed(0)}%';
    final plannedCount = _plannedExerciseIds?.length;
    final complete = avg >= 0.999;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B184A), Color(0xFF141218)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(.25),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 8,
            percent: avg.clamp(0.0, 1.0),
            center: Text(
              percentLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: .5,
              ),
            ),
            progressColor: _accent,
            backgroundColor: Colors.white12,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.planName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: complete
                            ? _success.withOpacity(.15)
                            : Colors.white.withOpacity(.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: complete ? _success : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            complete
                                ? Icons.check_circle
                                : Icons.fitness_center,
                            size: 14,
                            color: complete ? _success : Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            complete ? 'Hoàn thành' : 'Đang tập',
                            style: TextStyle(
                              color: complete ? _success : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _miniStat(
                      label: plannedCount != null ? 'Kế hoạch' : 'Logs',
                      value: plannedCount != null
                          ? '$plannedCount bài tập'
                          : '${widget.exercises.length}',
                      icon: Icons.list_alt,
                    ),
                    if (plannedCount != null)
                      _miniStat(
                        label: 'Đã log',
                        value: '${widget.exercises.length}',
                        icon: Icons.task_alt,
                      ),
                    _miniStat(
                      label: 'Thời gian',
                      value: _formatDuration(_calculateTotalTime()),
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),
                if (_missingExerciseCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _veryLow.withOpacity(.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _veryLow, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: _veryLow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Còn thiếu $_missingExerciseCount bài tập',
                          style: TextStyle(
                            color: _veryLow,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _progressBarInline(avg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBarInline(double p) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: p.clamp(0.0, 1.0),
      minHeight: 8,
      backgroundColor: Colors.white12,
      valueColor: const AlwaysStoppedAnimation(_accent),
    ),
  );

  // _exerciseItem removed after grouping refactor

  // ============== GROUPED UI ==============
  SliverList _groupedExerciseList() {
    final grouped = _groupedLogs;
    final keys = grouped.keys.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, index) {
        final exId = keys[index];
        final logs = grouped[exId]!;
        final name = _resolveExerciseName(logs.first);
        // Tính tổng progress cap 1.0
        double sum = 0;
        for (final l in logs) {
          sum += _resolveProgress(l);
        }
        if (sum > 1.0) sum = 1.0;
        final expanded = _expanded.contains(exId);
        final singleLog =
            logs.length == 1; // nếu chỉ có 1 log không cần nhóm/expand
        if (singleLog) {
          final l = logs.first;
          // render giống child nhưng với tên bài tập + 1 progress bar lớn hơn
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _cardBase,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDetail(l, name),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _gradientProgress(sum, height: 10),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            'Lần 1',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${(sum * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _cardBase,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              // Không đổi toàn bộ sang xanh; giữ neutral nếu đã xong
              color: _cardBorder,
              width: 1,
            ),
            boxShadow: [
              if (expanded)
                BoxShadow(
                  color: _accent.withOpacity(.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (expanded) {
                      _expanded.remove(exId);
                    } else {
                      _expanded.add(exId);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(18),
                splashColor: _accent.withOpacity(.15),
                highlightColor: Colors.white.withOpacity(.05),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _gradientProgress(sum, height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Tổng % vẫn hiển thị đơn giản, không đổi màu viền toàn bộ
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.06),
                              border: Border.all(color: Colors.white12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(sum * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              AnimatedRotation(
                                turns: expanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'x${logs.length}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                crossFadeState: expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 350),
                firstCurve: Curves.easeOutCubic,
                secondCurve: Curves.easeInCubic,
                sizeCurve: Curves.easeInOut,
                firstChild: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      for (var i = 0; i < logs.length; i++)
                        _childLogRow(logs[i], name, exId, indexInGroup: i),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }, childCount: keys.length),
    );
  }

  Widget _childLogRow(
    Map<String, dynamic> raw,
    String parentName,
    String exId, {
    int? indexInGroup,
  }) {
    final p = _resolveProgress(raw);

    // Tìm thời gian trong workoutExercise trước
    int? time;
    if (raw['workoutExercise'] is Map) {
      final workoutExercise = raw['workoutExercise'] as Map;
      if (workoutExercise['totalTime'] is num) {
        time = workoutExercise['totalTime'] as int;
      }
    }
    // Fallback: tìm ở root level
    if (time == null) {
      for (final key in ['totalTime', 'totalTimeSec', 'duration']) {
        if (raw[key] is num) {
          time = raw[key] as int;
          break;
        }
      }
    }

    debugPrint('[Time Debug] Log time: $time (raw: $raw)');
    // Harmonized ramp: veryLow (0-0.25), low (0.25-0.5), medium (0.5-0.75), accent (0.75-<1), success (1)
    final color = p >= 1.0
        ? _success
        : p >= 0.75
        ? _accent
        : p >= 0.5
        ? _medium
        : p >= 0.25
        ? _low
        : _veryLow;
    return InkWell(
      onTap: () => _openDetail(raw, parentName),
      borderRadius: BorderRadius.circular(12),
      splashColor: _accent.withOpacity(.15),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _cardElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        indexInGroup != null
                            ? 'Lần ${indexInGroup + 1}'
                            : 'Lần',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .2,
                        ),
                      ),
                      if (time != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.04),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(time),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _gradientProgress(p, height: 8, color: color),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(p * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Reusable Mini Stat Chip =====
  Widget _miniStat({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===== Gradient Progress Bar (Custom) =====
  Widget _gradientProgress(double value, {double height = 8, Color? color}) {
    final v = value.clamp(0.0, 1.0);
    final barColor = color ?? _accent;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * v;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.06),
            borderRadius: BorderRadius.circular(height),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(
                  colors: [barColor.withOpacity(.15), barColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== Shimmer Placeholder List =====
  SliverToBoxAdapter _buildShimmerList() {
    return SliverToBoxAdapter(
      child: Column(children: List.generate(3, (i) => _shimmerCard())),
    );
  }

  Widget _shimmerCard() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, _) {
        final t = _shimmerCtrl.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12, width: 1),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(.04),
                Colors.white.withOpacity(.08),
                Colors.white.withOpacity(.04),
              ],
              stops: [0, (0.25 + t * 0.5).clamp(0.0, 1.0), 1],
              begin: Alignment(-1, 0),
              end: Alignment(1, 0),
            ),
          ),
        );
      },
    );
  }

  void _openDetail(Map<String, dynamic> e, String fallbackName) {
    final title = _resolveExerciseName(e); // sẽ ưu tiên model nếu đã fetch
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          final exId = _extractExerciseId(e);
          final model = exId != null ? _exerciseCache[exId] : null;
          final specs = <ExerciseSpec>[];
          if (model != null) {
            if (model.defaultSets != null) {
              specs.add(
                ExerciseSpec(name: 'Sets', value: model.defaultSets.toString()),
              );
            }
            if (model.defaultReps != null) {
              specs.add(
                ExerciseSpec(name: 'Reps', value: model.defaultReps.toString()),
              );
            }
            if (model.defaultWeight != null) {
              specs.add(
                ExerciseSpec(name: 'Weight', value: '${model.defaultWeight}kg'),
              );
            }
            if (model.restTime != null) {
              specs.add(
                ExerciseSpec(name: 'Rest', value: '${model.restTime}s'),
              );
            }
            if (model.muscleGroupNames.isNotEmpty) {
              specs.add(
                ExerciseSpec(
                  name: 'Muscles',
                  value: model.muscleGroupNames.join(', '),
                ),
              );
            }
          }
          final calories = model?.met != null
              ? (model!.met! * 3.5 * 70 / 200).round().toString()
              : '0';
          return ExerciseDetailScreen(
            exerciseName: model?.name ?? title,
            author: model?.userName ?? 'Không có tác giả',
            calories: '$calories cal',
            description: model?.description ?? model?.instruction ?? '',
            backgroundImage: model?.videoUrl ?? 'bg',
            specs: specs,
          );
        },
      ),
    );
  }
}
