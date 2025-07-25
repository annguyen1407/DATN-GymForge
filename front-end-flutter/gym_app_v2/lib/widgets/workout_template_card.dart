// Dùng ở: workout_screen tab "Khám phá". Card hiển thị thông tin buổi tập template.
import 'package:flutter/material.dart';

class WorkoutTemplateCard extends StatelessWidget {
  final String image;
  final String title;
  final String? author;
  final double? rating;
  final String? tag;
  final int? days;
  final bool showAccept;
  final VoidCallback? onAccept;
  final bool compact;
  final bool dimmed;

  const WorkoutTemplateCard({
    required this.image,
    required this.title,
    this.author,
    this.rating,
    this.tag,
    this.days,
    this.showAccept = false,
    this.onAccept,
    this.compact = false,
    this.dimmed = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Dạng nhỏ gọn: row, hình nhỏ, thông tin ngắn gọn
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: image.isNotEmpty
                  ? Image.asset(
                      image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.deepPurple[300],
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.deepPurple[300],
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                    if (days != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '$days ngày',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (showAccept)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onAccept,
                  child: const Text(
                    'Chấp nhận',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    // Card lớn, bo góc lớn, overlay tối nếu dimmed, giống thiết kế
    return AspectRatio(
      aspectRatio: 1.8,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: image.isNotEmpty
                  ? Image.asset(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.deepPurple[300]),
                    )
                  : Container(color: Colors.deepPurple[300]),
            ),
            // Overlay tối nếu dimmed hoặc showAccept
            if (dimmed || showAccept)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(showAccept ? 0.55 : 0.35),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            // Tag (nếu có)
            if (tag != null)
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
                    tag!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            // Title, days
            Positioned(
              left: 16,
              bottom: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (days != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '$days ngày',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Nút Accept (nếu có)
            if (showAccept)
              Positioned(
                right: 16,
                bottom: 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onAccept,
                  child: const Text('Accept'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
