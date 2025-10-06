import 'package:flutter/material.dart';
import '../../repositories/exercises_repository.dart';
import '../../services/user_service.dart';
import '../../models/exercise_model.dart';
import '../../widgets/exercise_hero_header.dart';
import '../../core/extensions/color_extensions.dart';
import '../../core/utils/text_normalizer.dart';

/// Màn hình xem chi tiết bài tập chỉ đọc (không chỉnh sets/reps).
/// Sử dụng ExerciseHeroHeader thống nhất với các màn khác.
class ExerciseInfoScreen extends StatefulWidget {
  final String exerciseId;
  final String? backgroundImage;
  const ExerciseInfoScreen({
    super.key,
    required this.exerciseId,
    this.backgroundImage,
  });

  @override
  State<ExerciseInfoScreen> createState() => _ExerciseInfoScreenState();
}

class _ExerciseInfoScreenState extends State<ExerciseInfoScreen> {
  final _repo = ExercisesRepository();
  ExerciseModel? _exercise;
  bool _loading = true;
  String? _error;
  ExercisePerformanceModel? _performance;
  bool _perfLoading = false;

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
      final ex = await _repo.getById(widget.exerciseId);
      if (!mounted) return;
      if (ex == null) {
        setState(() => _error = 'Không tải được bài tập');
      } else {
        setState(() => _exercise = ex);
        _fetchPerformance();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchPerformance() async {
    setState(() => _perfLoading = true);
    try {
      final user = await UserService.fetchProfile(context);
      if (user == null) return;
      final perf = await _repo.getPerformanceForExercise(
        exerciseId: widget.exerciseId,
        userId: user.id,
      );
      if (!mounted) return;
      setState(() => _performance = perf);
    } catch (_) {
      // silent fail for performance
    } finally {
      if (mounted) setState(() => _perfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // description = giới thiệu (intro), instruction = hướng dẫn chi tiết
    final description = _exercise?.description?.trim().normalizedMultiline();
    final instruction = _exercise?.instruction?.trim().normalizedMultiline();
    final videoUrl = _exercise?.videoUrl;
    final bgImage = (videoUrl == null || videoUrl.isEmpty)
        ? widget.backgroundImage
        : null;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0E),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: Colors.pinkAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExerciseHeroHeader(
                title: _exercise?.name ?? 'Đang tải...',
                loadingTitle: _exercise == null,
                muscleGroups: _exercise?.muscleGroupNames ?? const [],
                backgroundImage: bgImage,
                videoUrl: videoUrl,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_performance != null || _perfLoading)
                      _PerformanceStats(
                        perf: _performance,
                        loading: _perfLoading,
                      ),
                    if (_performance != null || _perfLoading)
                      const SizedBox(height: 28),
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacityRatio(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.redAccent.withOpacityRatio(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _fetch,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    else if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                    const _SectionTitle(text: 'Giới thiệu'),
                    const SizedBox(height: 10),
                    _ExpandableBodyText(
                      text: (description != null && description.isNotEmpty)
                          ? description
                          : 'Chưa có giới thiệu cho bài tập này.',
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(text: 'Hướng dẫn'),
                    const SizedBox(height: 10),
                    _ExpandableBodyText(
                      text: (instruction != null && instruction.isNotEmpty)
                          ? instruction
                          : (description?.isNotEmpty == true
                                ? description!
                                : 'Chưa có hướng dẫn chi tiết.'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _ExpandableBodyText extends StatefulWidget {
  final String text;
  final int maxLines; // số dòng khi thu gọn
  const _ExpandableBodyText({required this.text, this.maxLines = 5})
    : assert(maxLines > 0, 'maxLines phải > 0');

  @override
  State<_ExpandableBodyText> createState() => _ExpandableBodyTextState();
}

class _ExpandableBodyTextState extends State<_ExpandableBodyText> {
  bool _expanded = false;
  bool _overflow = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measure();
  }

  @override
  void didUpdateWidget(covariant _ExpandableBodyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.maxLines != widget.maxLines) {
      _measure();
    }
  }

  void _measure() {
    final span = TextSpan(
      text: widget.text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13.5,
        height: 1.45,
      ),
    );
    final tp = TextPainter(
      text: span,
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    );
    final maxWidth =
        MediaQuery.of(context).size.width - 32; // 16 padding each side
    tp.layout(maxWidth: maxWidth);
    final overflow = tp.didExceedMaxLines;
    if (mounted) setState(() => _overflow = overflow);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: Stack(
            children: [
              Text(
                widget.text,
                softWrap: true,
                maxLines: _expanded ? null : widget.maxLines,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              if (_overflow && !_expanded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.18),
                            Colors.black.withOpacity(0.32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_overflow)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? 'Thu gọn' : 'Xem thêm',
                    style: const TextStyle(
                      color: Color(0xFFFF4E74),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 240),
                    turns: _expanded ? 0.5 : 0.0,
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.expand_more,
                      size: 18,
                      color: Color(0xFFFF4E74),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PerformanceStats extends StatelessWidget {
  final ExercisePerformanceModel? perf;
  final bool loading;
  const _PerformanceStats({required this.perf, required this.loading});

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _trendColor(String t) {
    switch (t) {
      case 'positive':
        return const Color(0xFF4CAF50);
      case 'negative':
        return const Color(0xFFFF5252);
      default:
        return Colors.amberAccent;
    }
  }

  IconData _trendIcon(String t) {
    switch (t) {
      case 'positive':
        return Icons.trending_up;
      case 'negative':
        return Icons.trending_down;
      default:
        return Icons.horizontal_rule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF15161A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: loading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.pinkAccent,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Đang tải hiệu suất...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            )
          : perf == null
          ? const Text(
              'Chưa có dữ liệu hiệu suất cho bài tập này.',
              style: TextStyle(color: Colors.white54, fontSize: 12.5),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _trendIcon(perf!.progressTrend),
                      size: 18,
                      color: _trendColor(perf!.progressTrend),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      perf!.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _trendColor(
                          perf!.progressTrend,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        perf!.progressTrend == 'positive'
                            ? 'Tăng'
                            : perf!.progressTrend == 'negative'
                            ? 'Giảm'
                            : 'Ổn định',
                        style: TextStyle(
                          color: _trendColor(perf!.progressTrend),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(
                      label: 'Số lần tập',
                      value: perf!.totalSessions.toString(),
                    ),
                    if (perf!.bestWeight > 0)
                      _StatChip(
                        label: 'Mức tạ tối đa',
                        value: '${perf!.bestWeight}kg',
                      ),
                    if (perf!.bestReps > 0)
                      _StatChip(
                        label: 'Số rep tối đa',
                        value: perf!.bestReps.toString(),
                      ),
                    if (perf!.totalCaloriesBurned > 0)
                      _StatChip(
                        label: 'Calo',
                        value: perf!.totalCaloriesBurned.toStringAsFixed(0),
                      ),
                    _StatChip(
                      label: 'Lần cuối',
                      value: _formatDate(perf!.lastPerformed),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF202226),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
