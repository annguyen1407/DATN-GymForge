import 'package:flutter/material.dart';
import '../../repositories/exercises_repository.dart';
import '../../models/exercise_model.dart';
import '../../widgets/exercise_hero_header.dart';
import '../../core/extensions/color_extensions.dart';

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
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instruction = _exercise?.instruction?.trim();
    final description = _exercise?.description?.trim();
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
                backgroundImage: widget.backgroundImage,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      text: (instruction != null && instruction.isNotEmpty)
                          ? instruction
                          : 'Chưa có giới thiệu cho bài tập này.',
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(text: 'Hướng dẫn'),
                    const SizedBox(height: 10),
                    _ExpandableBodyText(
                      text: (description != null && description.isNotEmpty)
                          ? description
                          : (instruction?.isNotEmpty == true
                              ? instruction!
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
    if (oldWidget.text != widget.text || oldWidget.maxLines != widget.maxLines) {
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
    final maxWidth = MediaQuery.of(context).size.width - 32; // 16 padding each side
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
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
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
