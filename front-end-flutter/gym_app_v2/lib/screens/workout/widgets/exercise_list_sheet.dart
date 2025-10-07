import 'package:flutter/material.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/exercise_card.dart';
import 'exercise_card.dart';

/// Widget hiển thị danh sách các bài tập dưới dạng bottom sheet
class ExerciseListSheet extends StatelessWidget {
  final List<ExerciseItem> exercises;
  final int currentExerciseIndex;
  final Map<int, List<Map<String, dynamic>>> workoutData;

  const ExerciseListSheet({
    super.key,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.workoutData,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.5, // cố định nửa màn hình
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.55),
            blurRadius: 26,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 54,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    'Danh sách bài tập',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chỉ xem – không thể đổi bài ở đây',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];
                final isActive = index == currentExerciseIndex;
                final setsDone = workoutData[index]?.length ?? 0;
                final hasLogs = setsDone > 0;
                final isCompleted = hasLogs; // chỉ coi là hoàn thành khi có log
                final isSkipped =
                    index < currentExerciseIndex &&
                    !hasLogs; // đã đi qua nhưng chưa log
                final totalSets = ex.sets;

                return WorkoutExerciseCard(
                  exercise: ex,
                  index: index,
                  isActive: isActive,
                  isCompleted: isCompleted,
                  isSkipped: isSkipped,
                  setsDone: setsDone,
                  totalSets: totalSets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.text(
                    label: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    size: AppButtonSize.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàm tiện ích để hiển thị bottom sheet chứa danh sách bài tập
void showExerciseListSheet({
  required BuildContext context,
  required List<ExerciseItem> exercises,
  required int currentExerciseIndex,
  required Map<int, List<Map<String, dynamic>>> workoutData,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return ExerciseListSheet(
        exercises: exercises,
        currentExerciseIndex: currentExerciseIndex,
        workoutData: workoutData,
      );
    },
  );
}
