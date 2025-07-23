import 'package:flutter/material.dart';

/// WorkoutScreen: Tab "Workout" hiển thị các nhóm workout, tab, search, category icon
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs điều hướng giữa các nhóm workout
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Tab(label: 'Khám phá', selected: true),
                  const SizedBox(width: 16),
                  _Tab(label: 'Kế hoạch'),
                  const SizedBox(width: 16),
                  _Tab(label: 'Chuyên gia'),
                ],
              ),
              const SizedBox(height: 20),
              // Ô tìm kiếm workout
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _CategoryIcon(
                    icon: Icons.directions_run,
                    color: Color(0xFFB86B5B),
                    label: 'Cardio',
                  ),
                  _CategoryIcon(
                    icon: Icons.fitness_center,
                    color: Color(0xFF7B5FB2),
                    label: 'Strength',
                  ),
                  _CategoryIcon(
                    icon: Icons.timer,
                    color: Color(0xFF4CB7A5),
                    label: 'Endurance',
                  ),
                  _CategoryIcon(
                    icon: Icons.accessibility_new,
                    color: Color(0xFF4C7CB7),
                    label: 'Flexibility',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Exclusive workout sets
              _SectionHeader(title: 'Exclusive workout sets'),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _WorkoutCard(
                      image: 'assets/images/cardio1.jpg',
                      title: 'Cardio training sets',
                      author: 'Robert Fox',
                      rating: 4.8,
                      tag: 'Premium',
                    ),
                    SizedBox(width: 16),
                    _WorkoutCard(
                      image: 'assets/images/cardio2.jpg',
                      title: 'Cardio HIIT',
                      author: 'Jane Cooper',
                      rating: 4.7,
                      tag: 'Free',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Quick workouts
              _SectionHeader(title: 'Quick workouts'),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _WorkoutCard(
                      image: 'assets/images/pushup.jpg',
                      title: 'Quick Push up',
                      author: 'Diana Richards',
                      rating: 4.5,
                      tag: 'Free',
                    ),
                    SizedBox(width: 16),
                    _WorkoutCard(
                      image: 'assets/images/flexibility1.jpg',
                      title: 'Flexibility',
                      author: 'James Lee',
                      rating: 4.6,
                      tag: 'Free',
                    ),
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

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  const _Tab({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF8854FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _CategoryIcon({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          'See all',
          style: TextStyle(
            color: Colors.purple[200],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String image;
  final String title;
  final String author;
  final double rating;
  final String tag;
  const _WorkoutCard({
    required this.image,
    required this.title,
    required this.author,
    required this.rating,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[800]),
              ),
            ),
            // Tag
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tag == 'Premium' ? Colors.amber : Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            // Title, author, rating
            Positioned(
              left: 12,
              bottom: 16,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
