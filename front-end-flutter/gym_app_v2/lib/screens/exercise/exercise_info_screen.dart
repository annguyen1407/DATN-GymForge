import 'package:flutter/material.dart';
import '../../repositories/exercises_repository.dart';
import '../../models/exercise_model.dart';
import '../../widgets/exercise_hero_header.dart';
import '../../widgets/app_snack_bar.dart';
import '../../core/extensions/color_extensions.dart';

/// Màn hình xem chi tiết bài tập chỉ đọc (không chỉnh sets/reps).
/// Sử dụng ExerciseHeroHeader thống nhất với các màn khác.
class ExerciseInfoScreen extends StatefulWidget {
  final String exerciseId;
  final String? backgroundImage;
  const ExerciseInfoScreen({super.key, required this.exerciseId, this.backgroundImage});

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
                  action: (_exercise != null)
                      ? IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.white),
                          onPressed: () {
                            AppSnackBar.showInfo(context, 'Tính năng copy chưa hỗ trợ');
                          },
                        )
                      : null,
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
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
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
                              TextButton(onPressed: _fetch, child: const Text('Thử lại')),
                            ],
                          ),
                        )
                      else if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: Colors.pinkAccent),
                          ),
                        ),
                      const _SectionTitle(text: 'Giới thiệu'),
                      const SizedBox(height: 10),
                      Text(
                        (instruction != null && instruction.isNotEmpty)
                            ? instruction
                            : 'Chưa có giới thiệu cho bài tập này.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(text: 'Hướng dẫn'),
                      const SizedBox(height: 10),
                      Text(
                        (description != null && description.isNotEmpty)
                            ? description
                            : (instruction?.isNotEmpty == true
                                ? instruction!
                                : 'Chưa có hướng dẫn chi tiết.'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
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
