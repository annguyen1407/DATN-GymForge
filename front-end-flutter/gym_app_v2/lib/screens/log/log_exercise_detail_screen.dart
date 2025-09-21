import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
import '../../widgets/app_button.dart';

/// LogExerciseDetailScreen: Màn hình chi tiết một bài tập cụ thể
/// Hiển thị video demo, thông tin chi tiết và các thông số của bài tập
class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseName; // Tên bài tập (VD: "Barbell Bench Press")
  final String author; // Tác giả (VD: "Tao bởi ban")
  final String calories; // Calories (VD: "200 calories")
  final String description; // Mô tả bài tập
  final String backgroundImage; // Hình nền/video
  final List<ExerciseSpec> specs; // Thông số bài tập

  const ExerciseDetailScreen({
    required this.exerciseName,
    required this.author,
    required this.calories,
    required this.description,
    required this.backgroundImage,
    required this.specs,
    super.key,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với video/hình nền và thông tin bài tập
            SizedBox(
              height: 500, // Cao hơn để chứa nhiều thông tin
              width: double.infinity,
              child: Stack(
                children: [
                  // Hình nền/Video
                  Positioned.fill(
                    child: widget.backgroundImage.isNotEmpty
                        ? Image.asset(
                            widget.backgroundImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey[800]),
                          )
                        : Container(color: Colors.grey[800]),
                  ),
                  // Overlay gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacityRatio(0.3),
                            Colors.black.withOpacityRatio(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // App bar
                  Positioned(
                    top: MediaQuery.of(context).padding.top,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  // Play button ở giữa image - nhỏ hơn và dịch lên trên
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 80, // Dịch lên trên bằng cách tăng bottom
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Play video
                        },
                        child: Container(
                          width: 80, // Giảm từ 100 xuống 80
                          height: 80, // Giảm từ 100 xuống 80
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacityRatio(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacityRatio(0.5),
                              width: 2,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(
                              6,
                            ), // Giảm từ 8 xuống 6
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacityRatio(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 40, // Giảm từ 50 xuống 40
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Thông tin bài tập ở dưới
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exerciseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.author,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.calories,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            // TODO: Expand/collapse description
                          },
                          child: const Text(
                            'Read More...',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Equipment section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dụng cụ tập luyện',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Align equipment to left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildEquipmentItem('Barbell'),
                  ),
                ],
              ),
            ),
            // Specifications section - cố định không scroll
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tùy chỉnh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Danh sách thông số cố định - không scroll
                  ...widget.specs.map((spec) => _buildCompactSpecItem(spec)),
                ],
              ),
            ),
            const SizedBox(height: 20), // Padding dưới cùng
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị equipment
  Widget _buildEquipmentItem(String name) {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacityRatio(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, color: Colors.white70, size: 24),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị từng thông số - có thể config được
  Widget _buildCompactSpecItem(ExerciseSpec spec) {
    return GestureDetector(
      onTap: () {
        // TODO: Mở dialog để chỉnh sửa thông số
        _showConfigDialog(spec);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacityRatio(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              spec.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  spec.value,
                  style: const TextStyle(
                    color: Colors.orange, // Đổi màu để nhấn mạnh có thể config
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit, // Đổi icon thành edit để rõ là có thể config
                  color: Colors.orange,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị dialog để config thông số
  void _showConfigDialog(ExerciseSpec spec) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Chỉnh sửa ${spec.name}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Tính năng config sẽ được thêm ở đây',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            AppButton.text(
              label: 'Đóng',
              onPressed: () => Navigator.pop(context),
              fullWidth: false,
              size: AppButtonSize.small,
            ),
          ],
        );
      },
    );
  }
}

/// Model cho thông số bài tập
class ExerciseSpec {
  final String name; // Tên thông số (VD: "Số hiệp", "Số rép")
  final String value; // Giá trị (VD: "3", "8")

  const ExerciseSpec({required this.name, required this.value});
}
