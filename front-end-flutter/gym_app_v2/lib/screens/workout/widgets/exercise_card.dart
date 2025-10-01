import 'package:flutter/material.dart';
import '../../../widgets/exercise_card.dart';
import 'status_chip.dart';

/// Card hiển thị thông tin bài tập trong danh sách bài tập buổi luyện tập
class WorkoutExerciseCard extends StatelessWidget {
  final ExerciseItem exercise;
  final int index;
  final bool isActive;
  final bool isCompleted;
  final bool isSkipped;
  final int setsDone;
  final int totalSets;

  const WorkoutExerciseCard({
    Key? key,
    required this.exercise,
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.isSkipped,
    required this.setsDone,
    required this.totalSets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = totalSets == 0 ? 0 : (setsDone / totalSets).clamp(0, 1);
    Color baseColor;
    if (isActive) {
      baseColor = const Color(0xFFFF8A65);
    } else if (isCompleted) {
      baseColor = Colors.green[700]!;
    } else {
      baseColor = const Color(0xFF1E1E1E);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isActive
            ? const LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 187, 0),
                  Color.fromARGB(255, 255, 157, 0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  baseColor.withOpacity(.95),
                  baseColor.withOpacity(.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: isActive ? Colors.orangeAccent : Colors.white10,
          width: 1.1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.orange.withOpacity(.35),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.black.withOpacity(.15)
                  : Colors.white.withOpacity(.07),
              border: Border.all(
                color: isActive ? Colors.black26 : Colors.white12,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Middle content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive ? Colors.black : Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                    StatusChip(
                      isActive: isActive,
                      isDone: isCompleted,
                      isSkipped: isSkipped,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.view_agenda,
                      size: 14,
                      color: isActive
                          ? Colors.black54
                          : isCompleted
                          ? Colors.white60
                          : Colors.white30,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$setsDone/$totalSets sets',
                      style: TextStyle(
                        color: isActive
                            ? Colors.black87
                            : isCompleted
                            ? Colors.white70
                            : Colors.white54,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: isActive
                          ? Colors.black45
                          : isCompleted
                          ? Colors.white54
                          : Colors.white24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exercise.restTime}s rest',
                      style: TextStyle(
                        color: isActive
                            ? Colors.black54
                            : isCompleted
                            ? Colors.white70
                            : Colors.white38,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                if (!isActive && !isCompleted) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 14,
                        color: Colors.white30,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${exercise.repsCount} reps • ' +
                              (exercise.weight == 0
                                  ? 'Bodyweight'
                                  : '${exercise.weight}kg'),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: .2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isActive
                        ? Colors.black.withOpacity(.15)
                        : Colors.white.withOpacity(.07),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? Colors.greenAccent
                          : isActive
                          ? Colors.black
                          : Colors.white24,
                    ),
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
