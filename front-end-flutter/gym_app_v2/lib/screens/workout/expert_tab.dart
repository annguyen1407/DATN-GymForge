import 'package:flutter/material.dart';
import '../../widgets/workout_card.dart';
import 'workout_detail_screen.dart';

class ExpertTab extends StatelessWidget {
  const ExpertTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        WorkoutCard(
          image: '', // removed missing asset
          title: 'Cardio training sets',
          subtitle: 'HLV Nguyễn Văn A',
          badge: '3 ngày',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutDetailScreen(
                  image: '',
                  title: 'Cardio training sets',
                  subtitle: 'HLV Nguyễn Văn A - Chuyên gia Cardio',
                  description:
                      'Chương trình cardio chuyên nghiệp được thiết kế bởi huấn luyện viên có 10 năm kinh nghiệm.',
                  exercises: const [
                    WorkoutExercise(
                      title: 'Bài tập 1',
                      description: 'Đánh giá thể trạng - 45 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 2',
                      description: 'Cardio cường độ thấp - 50 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 3',
                      description: 'HIIT Training - 40 phút',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        WorkoutCard(
          image: '',
          title: 'Quick Push up',
          subtitle: 'HLV Trần Thị B',
          badge: '4 ngày',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutDetailScreen(
                  image: '',
                  title: 'Quick Push up',
                  subtitle: 'HLV Trần Thị B - Chuyên gia Cơ tay',
                  description:
                      'Chương trình tập push-up chuyên sâu với các biến thể nâng cao từ huấn luyện viên chuyên về cơ tay.',
                  exercises: const [
                    WorkoutExercise(
                      title: 'Bài tập 1',
                      description: 'Push-up form chuẩn - 30 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 2',
                      description: 'Push-up biến thể - 35 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 3',
                      description: 'Push-up plyometric - 40 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 4',
                      description: 'Push-up challenge - 45 phút',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        WorkoutCard(
          image: '',
          title: 'Flexibility training sets',
          subtitle: 'HLV Lê Văn C',
          badge: 'Premium',
          badgeColor: Colors.amber,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutDetailScreen(
                  image: '',
                  title: 'Flexibility training sets',
                  subtitle: 'HLV Lê Văn C - Master Trainer Yoga',
                  description:
                      'Chương trình dẻo dai cao cấp từ Master Trainer với chứng chỉ quốc tế về Yoga và Pilates.',
                  exercises: const [
                    WorkoutExercise(
                      title: 'Bài tập 1',
                      description: 'Đánh giá độ dẻo dai - 40 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 2',
                      description: 'Hatha Yoga cơ bản - 60 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 3',
                      description: 'Vinyasa Flow - 75 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 4',
                      description: 'Advanced Poses - 90 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 5',
                      description: 'Meditation & Relax - 45 phút',
                    ),
                    WorkoutExercise(
                      title: 'Bài tập 6',
                      description: 'Personal Assessment - 60 phút',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
