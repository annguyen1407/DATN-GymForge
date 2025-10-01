import 'package:flutter/material.dart';
import '../../widgets/exercise_hero_header.dart';
import '../../models/exercise_model.dart';

/// New log exercise detail screen (lightweight):
/// - Receives workoutExerciseLogId (id của bản ghi log bài tập)
/// - Shows unified ExerciseHeroHeader
/// - Placeholder sections chờ API (thông số, lịch sử, biểu đồ)
class ExerciseLogDetailScreen extends StatelessWidget {
  final String workoutExerciseLogId; // id bản ghi log (workoutExerciseLog)
  final String? exerciseName; // optional: tên bài tập (fallback nếu chưa fetch)
  final List<String> muscleGroups; // có thể rỗng, sẽ fetch sau
  final String? videoAsset; // tạm thời asset local
  final ExerciseModel? exerciseModel; // full exercise model

  const ExerciseLogDetailScreen({
    super.key,
    required this.workoutExerciseLogId,
    this.exerciseName,
    this.muscleGroups = const [],
    this.videoAsset,
    this.exerciseModel,
  });

  @override
  Widget build(BuildContext context) {
    // Use the model data when available, otherwise fall back to the individually provided values
    final name = exerciseModel?.name ?? exerciseName ?? 'Bài tập';
    final groups = exerciseModel?.muscleGroupNames ?? muscleGroups;
    final video = exerciseModel?.videoUrl ?? videoAsset;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ExerciseHeroHeader(
              title: name,
              muscleGroups: groups,
              onBack: () => Navigator.pop(context),
              backgroundImage: video,
              onPlay: () {},
              action: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz, color: Colors.white),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((exerciseModel?.instruction != null &&
                          exerciseModel!.instruction!.isNotEmpty) ||
                      (exerciseModel?.description != null &&
                          exerciseModel!.description!.isNotEmpty)) ...[
                    const _SectionTitle(text: 'Thông tin bài tập'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (exerciseModel?.instruction != null &&
                              exerciseModel!.instruction!.isNotEmpty) ...[
                            Text(
                              'Giới thiệu:',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exerciseModel!.instruction!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          if (exerciseModel?.description != null &&
                              exerciseModel!.description!.isNotEmpty) ...[
                            if (exerciseModel?.instruction != null &&
                                exerciseModel!.instruction!.isNotEmpty)
                              const SizedBox(height: 12),
                            Text(
                              'Hướng dẫn:',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exerciseModel!.description!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    _buildDetailDialog(context),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Xem chi tiết',
                                  style: TextStyle(
                                    color: Color(0xFFFF4E74),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: Color(0xFFFF4E74),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const _SectionTitle(text: 'Thông số (đang cập nhật)'),
                  const SizedBox(height: 10),
                  _placeholderCard(
                    'Sẽ hiển thị reps/sets/weight thời điểm log này. API sẽ cung cấp sau.',
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle(text: 'Lịch sử gần đây'),
                  const SizedBox(height: 10),
                  _placeholderCard(
                    'Danh sách các lần log gần đây của cùng bài tập.',
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle(text: 'Biểu đồ hiệu suất'),
                  const SizedBox(height: 10),
                  _placeholderCard(
                    'Biểu đồ tiến bộ (khối lượng nâng, thời gian, v.v.) sẽ hiển thị ở đây.',
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Log ID: $workoutExerciseLogId',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.35),
                        fontSize: 12,
                        letterSpacing: .3,
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

  // Using the _SectionTitle widget class instead of this method
  Widget _buildDetailDialog(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Thông tin chi tiết',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (exerciseModel?.instruction != null &&
                exerciseModel!.instruction!.isNotEmpty) ...[
              const Text(
                'Giới thiệu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exerciseModel!.instruction!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (exerciseModel?.description != null &&
                exerciseModel!.description!.isNotEmpty) ...[
              const Text(
                'Hướng dẫn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exerciseModel!.description!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCard(String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
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

// Removed expandable text widget as we're using a more compact display now
