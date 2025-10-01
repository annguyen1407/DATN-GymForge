import 'package:flutter/material.dart';

class BodyTab extends StatelessWidget {
  final double? weight;
  final double? height;
  final double? bmi;
  // onEdit retained for parent sheet invocation if needed
  final VoidCallback onEdit;
  const BodyTab({
    super.key,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.onEdit,
  });

  Map<String, dynamic> _bmiInfo(double v) {
    if (v < 18.5) {
      return {
        'label': 'Thiếu cân',
        'color': Colors.amber,
        'desc': 'Bạn có thể cần tăng thêm cân và chú ý dinh dưỡng.',
      };
    } else if (v < 23) {
      return {
        'label': 'Bình thường',
        'color': const Color(0xFF34C759),
        'desc': 'Chỉ số BMI ở mức tốt. Duy trì chế độ hiện tại.',
      };
    } else if (v < 25) {
      return {
        'label': 'Tiền thừa cân',
        'color': const Color(0xFFFFCC00),
        'desc': 'Nên theo dõi thêm và cân bằng dinh dưỡng.',
      };
    } else if (v < 30) {
      return {
        'label': 'Thừa cân',
        'color': const Color(0xFFFF9500),
        'desc': 'Tập luyện và kiểm soát calo sẽ giúp cải thiện.',
      };
    }
    return {
      'label': 'Béo phì',
      'color': const Color(0xFFFF3B30),
      'desc': 'Nên có kế hoạch tập luyện & dinh dưỡng chặt chẽ hơn.',
    };
  }

  Widget _metricTile(
    String title,
    String? value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color ?? const Color(0xFF8854FF)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value ?? '--',
              style: TextStyle(
                color: value == null ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAll = weight != null && height != null && bmi != null;
    final info = hasAll ? _bmiInfo(bmi!) : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ số cơ thể',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _metricTile(
                'Cân nặng',
                weight == null ? null : '${weight!.toStringAsFixed(1)} kg',
                Icons.monitor_weight,
              ),
              const SizedBox(width: 12),
              _metricTile(
                'Chiều cao',
                height == null ? null : '${height!.toStringAsFixed(1)} cm',
                Icons.height,
              ),
              const SizedBox(width: 12),
              _metricTile(
                'BMI',
                bmi == null ? null : bmi!.toStringAsFixed(2),
                Icons.scale,
                color: info?['color'],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (hasAll)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[850]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (info!['color'] as Color).withValues(
                            alpha: .18,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: (info['color'] as Color).withValues(
                              alpha: .55,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: info['color'],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              info['label'],
                              style: TextStyle(
                                color: info['color'],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    info['desc'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[850]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Chưa có dữ liệu',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cập nhật các dữ liệu ngày hoặc tập luyện để cập nhật chỉ số cơ thể ngày.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.35,
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
