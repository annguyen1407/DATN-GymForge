import 'package:flutter/material.dart';
import '../repositories/appointments_repository.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  /// Giữ "type" tạm thời để tương lai có thể style khác nếu cần (upcoming/completed/cancelled)
  final String type;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = appointment.date;
    // Tên gymer & coach (nếu response có đủ 2 chiều). Fallback giống cũ nếu thiếu.
    final coachName = appointment.coach?.user?.name;
    final gymerName = appointment.gymer?.user?.name;

    // Quy tắc hiển thị:
    // 1. Nếu có cả 2 -> dòng 1: Coach, dòng 2: Gymer
    // 2. Nếu chỉ có 1 -> hiển thị 1 dòng duy nhất.
    final hasBoth = coachName != null && gymerName != null;

    // Determine background color based on status & tab type
    final statusUpper = appointment.status.toUpperCase();
    Color? bgOverride;
    if (type == 'upcoming' && statusUpper == 'CONFIRMED') {
      bgOverride = const Color.fromARGB(255, 147, 125, 38); // light yellow
    } else if (type == 'completed') {
      bgOverride = const Color.fromARGB(255, 36, 134, 33); // pale green
    } else if (type == 'cancelled') {
      bgOverride = const Color.fromARGB(255, 123, 33, 33); // soft red
    }
    final bool lightBg = bgOverride != null; // xác định có nền sáng hay không

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: bgOverride ?? Colors.white.withOpacity(.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: bgOverride != null
                ? Colors.black.withOpacity(.06)
                : Colors.white.withOpacity(.07),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar (màu xám & hình tròn theo yêu cầu)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
                border: Border.all(
                  color: (lightBg
                      ? Colors.black.withOpacity(.15)
                      : Colors.white.withOpacity(.08)),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.people_alt_rounded,
                color: lightBg
                    ? Colors.black.withOpacity(.8)
                    : Colors.white.withOpacity(.9),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Names block
                  if (hasBoth) ...[
                    _nameText(coachName, light: lightBg),
                    const SizedBox(height: 2),
                    _nameText(gymerName, subtle: true, light: lightBg),
                  ] else ...[
                    _nameText(
                      coachName ?? gymerName ?? 'Không xác định',
                      light: lightBg,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Date & time line
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: lightBg
                            ? Colors.black.withOpacity(.55)
                            : Colors.white.withOpacity(.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date != null ? _formatDateTime(date) : 'Chưa xác định',
                        style: TextStyle(
                          color: bgOverride != null
                              ? Colors.black.withOpacity(.70)
                              : Colors.white.withOpacity(.78),
                          fontSize: 13.2,
                          fontWeight: FontWeight.w500,
                          letterSpacing: .15,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: lightBg
                            ? Colors.black.withOpacity(.55)
                            : Colors.white.withOpacity(.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date != null
                            ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                            : '--:--',
                        style: TextStyle(
                          color: bgOverride != null
                              ? Colors.black.withOpacity(.82)
                              : Colors.white.withOpacity(.85),
                          fontSize: 13.4,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .2,
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

  Widget _nameText(
    String name, {
    String? label,
    bool subtle = false,
    bool light = false,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: name,
            style: TextStyle(
              color: light
                  ? (subtle
                        ? Colors.black.withOpacity(.70)
                        : Colors.black.withOpacity(.92))
                  : Colors.white.withOpacity(subtle ? .82 : .95),
              fontSize: 15.2,
              fontWeight: FontWeight.w600,
              letterSpacing: -.1,
            ),
          ),
          if (label != null) ...[
            TextSpan(
              text: '  •  ',
              style: TextStyle(
                color: light
                    ? Colors.black.withOpacity(.25)
                    : Colors.white.withOpacity(.30),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                color: light
                    ? Colors.black.withOpacity(.55)
                    : Colors.white.withOpacity(.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: .2,
              ),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];

    const weekdays = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];

    return '${weekdays[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }
}
