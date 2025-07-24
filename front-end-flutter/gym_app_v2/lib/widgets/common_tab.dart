// (Chưa thấy dùng trực tiếp trong screen nào). Tab tuỳ chỉnh, dùng cho các thanh tab chung.
import 'package:flutter/material.dart';

/// Widget tab dùng chung cho các màn hình, có thể chọn hoặc không chọn.
///
/// [label]: Nhãn hiển thị trên tab.
/// [selected]: Tab có đang được chọn không.
/// [onTap]: Hàm callback khi nhấn vào tab.
class CommonTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Tạo một CommonTab
  const CommonTab({
    required this.label,
    this.selected = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng GestureDetector để bắt sự kiện nhấn vào tab (nếu có onTap)
    return GestureDetector(
      onTap: onTap, // callback khi nhấn tab
      child: Container(
        // Padding cho tab để dễ bấm và đẹp hơn
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        // Bo góc và đổi màu nền nếu tab được chọn
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8854FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        // Hiển thị nhãn tab với style khác nhau nếu được chọn
        child: Text(
          label, // nội dung nhãn
          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.white54, // màu chữ theo trạng thái
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
