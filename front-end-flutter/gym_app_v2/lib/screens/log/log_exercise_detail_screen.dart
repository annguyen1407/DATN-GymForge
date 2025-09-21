import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';

/// LogExerciseDetailScreen: Màn hình chi tiết một bài tập cụ thể
/// Hiển thị video demo, thông tin chi tiết và các thông số của bài tập
class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseName; // Tên bài tập (VD: "Barbell Bench Press")
  final String author; // Tác giả (VD: "Tao bởi bạn")
  final String calories; // Ví dụ: "200 cal"
  final String description; // Mô tả bài tập
  final String backgroundImage; // Hình nền/video (local asset path)
  final List<ExerciseSpec> specs; // Thông số bài tập
  final List<String> equipment; // Danh sách dụng cụ

  const ExerciseDetailScreen({
    required this.exerciseName,
    required this.author,
    required this.calories,
    required this.description,
    required this.backgroundImage,
    required this.specs,
    this.equipment = const [],
    super.key,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 360,
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: _buildHeroHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow(),
                      const SizedBox(height: 20),
                      _buildDescription(),
                      const SizedBox(height: 28),
                      if (widget.equipment.isNotEmpty) _buildEquipmentSection(),
                      const SizedBox(height: 28),
                      _buildSpecsSection(),
                      SizedBox(height: media.padding.bottom + 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Positioned.fill(
          child: widget.backgroundImage.isNotEmpty
              ? Image.asset(
                  widget.backgroundImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[850]),
                )
              : Container(color: Colors.grey[850]),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),
        // Play button and title area
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.black,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.exerciseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _metaChip(Icons.person, widget.author),
                    _metaChip(
                      Icons.local_fire_department,
                      widget.calories,
                      iconColor: Colors.orangeAccent,
                    ),
                    if (widget.equipment.isNotEmpty)
                      _metaChip(
                        Icons.fitness_center,
                        '${widget.equipment.length} dụng cụ',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaChip(
    IconData icon,
    String label, {
    Color iconColor = Colors.white70,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Thông số bài tập',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        AppButton.text(
          label: 'Chia sẻ',
          onPressed: () {},
          fullWidth: false,
          size: AppButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final maxLines = _descExpanded ? null : 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          firstChild: Text(
            widget.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            widget.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          crossFadeState: _descExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _descExpanded = !_descExpanded),
          child: Text(
            _descExpanded ? 'Thu gọn' : 'Xem thêm...',
            style: const TextStyle(
              color: Color(0xFF8854FF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    return Column(
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
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final name = widget.equipment[index];
              return _equipmentChip(name);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: widget.equipment.length,
          ),
        ),
      ],
    );
  }

  Widget _equipmentChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fitness_center, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsSection() {
    return Column(
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.specs.map((s) => _specCard(s)).toList(),
        ),
      ],
    );
  }

  Widget _specCard(ExerciseSpec spec) {
    return GestureDetector(
      onTap: () => _showConfigDialog(spec),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              spec.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  spec.value,
                  style: const TextStyle(
                    color: Color(0xFFFFB020),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit, color: Color(0xFFFFB020), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: 14 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          // TODO: Replace deprecated withOpacity after confirming extension resolution across all files.
          color: Colors.black.withValues(alpha: 0.85),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton.primary(
                label: 'Bắt đầu tập',
                onPressed: () {},
                size: AppButtonSize.large,
              ),
            ),
            const SizedBox(width: 12),
            AppButton.outline(
              label: 'Ghi log',
              onPressed: () {},
              fullWidth: false,
              size: AppButtonSize.large,
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
