import 'package:flutter/material.dart';
import '../../widgets/workout_card.dart';
import 'workout_detail_screen.dart';

class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
          children: [
            WorkoutCard(
              image: 'assets/images/cardio1.jpg',
              title: 'Cardio training sets',
              subtitle: '3 ngày',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(
                      image: 'assets/images/cardio1.jpg',
                      title: 'Tập luyện tuần hoàn',
                      subtitle: 'HLV Nguyễn Văn A',
                      description:
                          'Chương trình tập luyện cardio giúp cải thiện sức khỏe tim mạch và đốt cháy calo hiệu quả.',
                      exercises: const [
                        WorkoutExercise(
                          title: 'Ngày 1',
                          description: 'Khởi động cơ bản - 30 phút',
                          isCompleted: true,
                        ),
                        WorkoutExercise(
                          title: 'Ngày 2',
                          description: 'Tập tốc độ - 45 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 3',
                          description: 'Tập sức bền - 60 phút',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            WorkoutCard(
              image: 'assets/images/pushup.jpg',
              title: 'Quick Push up',
              subtitle: '4 ngày',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(
                      image: 'assets/images/pushup.jpg',
                      title: 'Quick Push up',
                      subtitle: 'HLV Trần Thị B',
                      description:
                          'Chương trình tập push-up nhanh giúp tăng cường sức mạnh cơ tay và ngực.',
                      exercises: const [
                        WorkoutExercise(
                          title: 'Ngày 1',
                          description: 'Push-up cơ bản - 20 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 2',
                          description: 'Push-up nâng cao - 25 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 3',
                          description: 'Push-up biến thể - 30 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 4',
                          description: 'Push-up thử thách - 35 phút',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            WorkoutCard(
              image: 'assets/images/flexibility1.jpg',
              title: 'Flexibility training sets',
              subtitle: '6 ngày',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(
                      image: 'assets/images/flexibility1.jpg',
                      title: 'Flexibility training sets',
                      subtitle: 'HLV Lê Văn C',
                      description:
                          'Chương trình tập dẻo dai giúp cải thiện tính linh hoạt và giảm căng thẳng cơ bắp.',
                      exercises: const [
                        WorkoutExercise(
                          title: 'Ngày 1',
                          description: 'Khởi động dẻo dai - 20 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 2',
                          description: 'Yoga cơ bản - 30 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 3',
                          description: 'Stretching nâng cao - 35 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 4',
                          description: 'Pilates - 40 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 5',
                          description: 'Thư giãn cơ bắp - 25 phút',
                        ),
                        WorkoutExercise(
                          title: 'Ngày 6',
                          description: 'Tổng hợp dẻo dai - 45 phút',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            backgroundColor: Colors.redAccent,
            onPressed: () {},
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
