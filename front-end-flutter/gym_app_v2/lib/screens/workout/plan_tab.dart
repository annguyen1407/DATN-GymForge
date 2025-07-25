import 'package:flutter/material.dart';
import '../../widgets/workout_card.dart';

class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
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
