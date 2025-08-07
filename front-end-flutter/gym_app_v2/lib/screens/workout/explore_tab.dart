import 'package:flutter/material.dart';
import '../../widgets/workout_template_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/section_header.dart';
import 'workout_template_screen.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ô tìm kiếm workout
          Container(
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Các category icon đại diện cho nhóm workout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                CategoryIcon(
                  icon: Icons.directions_run,
                  color: Color(0xFFB86B5B),
                  label: 'Cardio',
                ),
                CategoryIcon(
                  icon: Icons.fitness_center,
                  color: Color(0xFF7B5FB2),
                  label: 'Strength',
                ),
                CategoryIcon(
                  icon: Icons.timer,
                  color: Color(0xFF4CB7A5),
                  label: 'Endurance',
                ),
                CategoryIcon(
                  icon: Icons.accessibility_new,
                  color: Color(0xFF4C7CB7),
                  label: 'Flexibility',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Exclusive workout sets
          const SectionHeader(title: 'Exclusive workout sets'),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutTemplateScreen(
                          image: 'assets/images/cardio1.jpg',
                          title: 'Cardio training sets',
                          tag: 'Premium',
                        ),
                      ),
                    );
                  },
                  child: const WorkoutTemplateCard(
                    image: '',
                    title: 'Cardio training sets',
                    author: 'Robert Fox',
                    rating: 4.8,
                    tag: 'Premium',
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutTemplateScreen(
                          image: 'assets/images/cardio2.jpg',
                          title: 'Cardio HIIT',
                          tag: 'Free',
                        ),
                      ),
                    );
                  },
                  child: const WorkoutTemplateCard(
                    image: '',
                    title: 'Cardio HIIT',
                    author: 'Jane Cooper',
                    rating: 4.7,
                    tag: 'Free',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Quick workouts
          const SectionHeader(title: 'Quick workouts'),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutTemplateScreen(
                          image: 'assets/images/pushup.jpg',
                          title: 'Quick Push up',
                          tag: 'Free',
                        ),
                      ),
                    );
                  },
                  child: const WorkoutTemplateCard(
                    image: '',
                    title: 'Quick Push up',
                    author: 'Diana Richards',
                    rating: 4.5,
                    tag: 'Free',
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutTemplateScreen(
                          image: 'assets/images/flexibility1.jpg',
                          title: 'Flexibility',
                          tag: 'Free',
                        ),
                      ),
                    );
                  },
                  child: const WorkoutTemplateCard(
                    image: '',
                    title: 'Flexibility',
                    author: 'James Lee',
                    rating: 4.6,
                    tag: 'Free',
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
