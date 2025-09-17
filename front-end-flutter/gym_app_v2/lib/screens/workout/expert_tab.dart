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
                builder: (_) => const WorkoutDetailScreen(
                  planId: 'mock-cardio-001', // mock plan id
                  image: '',
                  title: 'Cardio training sets',
                  subtitle: 'HLV Nguyễn Văn A - Chuyên gia Cardio',
                  description:
                      'Chương trình cardio chuyên nghiệp được thiết kế bởi huấn luyện viên có 10 năm kinh nghiệm. (Mock)',
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
                builder: (_) => const WorkoutDetailScreen(
                  planId: 'mock-pushup-002',
                  image: '',
                  title: 'Quick Push up',
                  subtitle: 'HLV Trần Thị B - Chuyên gia Cơ tay',
                  description:
                      'Chương trình tập push-up chuyên sâu với các biến thể nâng cao từ huấn luyện viên chuyên về cơ tay. (Mock)',
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
                builder: (_) => const WorkoutDetailScreen(
                  planId: 'mock-flexibility-003',
                  image: '',
                  title: 'Flexibility training sets',
                  subtitle: 'HLV Lê Văn C - Master Trainer Yoga',
                  description:
                      'Chương trình dẻo dai cao cấp từ Master Trainer với chứng chỉ quốc tế về Yoga và Pilates. (Mock)',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
