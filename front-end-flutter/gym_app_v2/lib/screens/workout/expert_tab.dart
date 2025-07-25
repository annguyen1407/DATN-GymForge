import 'package:flutter/material.dart';
import '../../widgets/workout_card.dart';

class ExpertTab extends StatelessWidget {
  const ExpertTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: const [
        WorkoutCard(
          image: 'assets/images/cardio1.jpg',
          title: 'Cardio training sets',
          days: 3,
        ),
        SizedBox(height: 16),
        WorkoutCard(
          image: 'assets/images/pushup.jpg',
          title: 'Quick Push up',
          days: 4,
        ),
        SizedBox(height: 16),
        WorkoutCard(
          image: 'assets/images/flexibility1.jpg',
          title: 'Flexibility training sets',
          days: 6,
          showAccept: true,
          dimmed: true,
        ),
      ],
    );
  }
}
