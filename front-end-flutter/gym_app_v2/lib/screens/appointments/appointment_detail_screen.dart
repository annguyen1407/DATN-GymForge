import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/appointments_repository.dart';
import '../../repositories/current_user_repository.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final AppointmentModel? initial;
  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.initial,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _repo = AppointmentsRepository();
  AppointmentModel? _detail;
  bool _loading = true;
  bool _error = false;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.initial; // optimistic seed
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final data = await _repo.fetchDetail(widget.appointmentId);
    if (!mounted) return;
    setState(() {
      if (data == null) {
        _error = true;
      } else {
        _detail = data;
      }
      _loading = false;
    });
  }

  String _statusLabel(String raw) {
    final s = raw.toUpperCase();
    switch (s) {
      case 'PENDING':
        return 'Đang chờ';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return raw;
    }
  }

  Color _statusColor(String raw) {
    final s = raw.toUpperCase();
    if (s == 'PENDING') return const Color.fromARGB(255, 252, 204, 29);
    if (s == 'CONFIRMED') return const Color(0xFF8E7CFF);
    if (s == 'COMPLETED') return const Color.fromARGB(255, 56, 228, 47);
    if (s == 'CANCELED' || s == 'CANCELLED') {
      return const Color.fromARGB(255, 255, 30, 30);
    }
    return Colors.white70;
  }

  Widget _statusBanner(AppointmentModel m) {
    final color = _statusColor(m.status);
    final label = _statusLabel(m.status);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // ignore: deprecated_member_use
          colors: [color.withOpacity(.22), color.withOpacity(.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(.55),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
          const Spacer(),
          Text(
            m.status.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(.45),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _detail;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Chi tiết lịch hẹn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_loading)
              const SizedBox()
            else if (_saving || _deleting)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _deleting ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ),
              )
            else
              IconButton(
                tooltip: 'Làm mới',
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchDetail,
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _error || model == null
            ? _buildError()
            : Column(
                children: [
                  Expanded(child: _buildContent(model)),
                  _buildActionBar(model),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final model = _detail;
    if (model == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Xóa lịch hẹn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa lịch hẹn này? Hành động không thể hoàn tác.',
          style: TextStyle(color: Colors.white70, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _deleting = true;
    });
    final success = await _repo.deleteAppointment(model.id);
    if (!mounted) return;
    setState(() {
      _deleting = false;
    });
    if (success) {
      Navigator.pop(context, 'deleted');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa lịch hẹn')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa thất bại')));
    }
  }

  void _openEditSheet() {
    final model = _detail;
    if (model == null) return;
    final noteCtrl = TextEditingController(text: model.note ?? '');
    final locationCtrl = TextEditingController(text: model.location ?? '');
    DateTime? selectedDate = model.date;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheet) {
              Future<void> pickDateTime() async {
                final now = DateTime.now();
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate:
                      selectedDate ?? now.add(const Duration(hours: 3)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (pickedDate == null) return;
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                    selectedDate ?? now.add(const Duration(hours: 3)),
                  ),
                );
                if (pickedTime == null) return;
                final combined = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                // Validate +3 hours
                if (combined.isBefore(now.add(const Duration(hours: 3)))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Thời gian phải cách hiện tại ít nhất 3 giờ',
                      ),
                    ),
                  );
                  return;
                }
                setSheet(() {
                  selectedDate = combined;
                });
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const Text(
                      'Chỉnh sửa lịch hẹn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Ghi chú'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: locationCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Địa điểm'),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: pickDateTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedDate != null
                                    ? _formatDate(selectedDate!) +
                                          '  •  ' +
                                          '${selectedDate!.hour.toString().padLeft(2, '0')}:${selectedDate!.minute.toString().padLeft(2, '0')}'
                                    : 'Chọn ngày giờ (cách hiện tại ≥ 3h)',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.9),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.edit_calendar,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E2DE2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (_saving) return;
                          // Lưu lại root context trước khi pop sheet.
                          final rootContext = this.context;
                          Navigator.pop(context); // đóng sheet
                          setState(() {
                            _saving = true;
                          });
                          final updated = await _repo.updateAppointment(
                            model.id,
                            date: selectedDate,
                            note: noteCtrl.text.trim(),
                            location: locationCtrl.text.trim(),
                          );
                          if (!mounted) return; // widget đã dispose
                          setState(() {
                            _saving = false;
                          });
                          if (updated != null) {
                            await _fetchDetail();
                            if (!mounted) return;
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật lịch hẹn'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                content: Text('Cập nhật thất bại'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withOpacity(.6)),
    filled: true,
    fillColor: Colors.white.withOpacity(.07),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF8E2DE2), width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.redAccent.withOpacity(.9),
          size: 48,
        ),
        const SizedBox(height: 12),
        const Text(
          'Không tải được dữ liệu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _fetchDetail, child: const Text('Thử lại')),
      ],
    ),
  );

  Widget _buildContent(AppointmentModel m) {
    final coachName = m.coach?.user?.name;
    final gymerName = m.gymer?.user?.name;
    final date = m.date;
    final dateStr = date != null ? _formatDate(date) : 'Chưa xác định';
    final timeStr = date != null
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '--:--';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusBanner(m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionCard([
              _rowLabelValue('Huấn luyện viên', coachName ?? '—'),
              const SizedBox(height: 10),
              _rowLabelValue('Học viên', gymerName ?? '—'),
            ]),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionCard([
              _rowLabelValue('Ngày', dateStr),
              const SizedBox(height: 10),
              _rowLabelValue('Giờ', timeStr),
            ]),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionCard([
              _rowLabelValue(
                'Ghi chú',
                (m.note?.trim().isNotEmpty ?? false) ? m.note!.trim() : '—',
              ),
              const SizedBox(height: 10),
              _rowLabelValue(
                'Địa điểm',
                (m.location?.trim().isNotEmpty ?? false)
                    ? m.location!.trim()
                    : '—',
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(AppointmentModel m) {
    // Xác định role & status để render nút
    // Giản lược: lấy role từ profile cache bằng CurrentUserRepository nhẹ (có thể tối ưu inject)
    // Ở đây tạm lấy trực tiếp qua repository mới cho nhanh (có thể refactor sau)
    return FutureBuilder(
      future: CurrentUserRepository().fetchProfile(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final role = snap.data?.role.toUpperCase();
        final status = m.status.toUpperCase();

        List<_ActionButton> buttons = [];
        if (role == 'GYMER') {
          if (status == 'PENDING' || status == 'CONFIRMED') {
            // Hiển thị chỉnh sửa & xóa
            buttons.add(
              _ActionButton(
                label: 'Chỉnh sửa',
                onTap: _openEditSheet,
                style: _ActionStyle.primary,
              ),
            );
            buttons.add(
              _ActionButton(
                label: 'Xóa',
                onTap: _confirmDelete,
                style: _ActionStyle.dangerOutline,
              ),
            );
          }
        } else if (role == 'COACH') {
          if (status == 'PENDING') {
            buttons.add(
              _ActionButton(
                label: 'Xác nhận',
                onTap: () => _updateStatus(m, 'CONFIRMED'),
                style: _ActionStyle.primary,
              ),
            );
            buttons.add(
              _ActionButton(
                label: 'Hủy bỏ',
                onTap: () => _updateStatus(m, 'CANCELED'),
                style: _ActionStyle.dangerOutline,
              ),
            );
          } else if (status == 'CONFIRMED') {
            buttons.add(
              _ActionButton(
                label: 'Hoàn thành',
                onTap: () => _updateStatus(m, 'COMPLETED'),
                style: _ActionStyle.success,
              ),
            );
            buttons.add(
              _ActionButton(
                label: 'Hủy bỏ',
                onTap: () => _updateStatus(m, 'CANCELED'),
                style: _ActionStyle.dangerOutline,
              ),
            );
          }
        }

        if (buttons.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.03),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(.06)),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: buttons
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: e.key == 0 ? 0 : 10,
                            right: e.key == buttons.length - 1 ? 0 : 0,
                          ),
                          child: _buildActionButton(e.value),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(AppointmentModel m, String target) async {
    if (_saving || _deleting) return;
    setState(() {
      _saving = true;
    });
    final updated = await _repo.updateAppointmentStatus(m.id, target);
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    if (updated != null) {
      await _fetchDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật trạng thái: ${_statusLabel(updated.status)}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái thất bại')),
      );
    }
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _rowLabelValue(String label, String value, {Color? badgeColor}) {
    final isBadge = badgeColor != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.6),
              fontSize: 13.2,
              fontWeight: FontWeight.w500,
              letterSpacing: .2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isBadge
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: badgeColor.withOpacity(.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .15,
                  ),
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Th1',
      'Th2',
      'Th3',
      'Th4',
      'Th5',
      'Th6',
      'Th7',
      'Th8',
      'Th9',
      'Th10',
      'Th11',
      'Th12',
    ];
    const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${weekdays[d.weekday % 7]}, ${d.day} ${months[d.month - 1]}';
  }

  // ----- Action Button Helper -----
  Widget _buildActionButton(_ActionButton btn) {
    Color bg;
    Color fg;
    BorderSide? side;
    switch (btn.style) {
      case _ActionStyle.primary:
        bg = const Color(0xFF8E2DE2);
        fg = Colors.white;
        break;
      case _ActionStyle.success:
        bg = const Color.fromARGB(255, 31, 150, 35);
        fg = Colors.white;
        break;
      case _ActionStyle.dangerOutline:
        bg = Colors.transparent;
        fg = Colors.redAccent;
        side = BorderSide(color: Colors.redAccent.withOpacity(.7), width: 1.2);
        break;
    }
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: side ?? BorderSide.none,
          ),
        ),
        onPressed: btn.onTap,
        child: Text(
          btn.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          ),
        ),
      ),
    );
  }
}

enum _ActionStyle { primary, success, dangerOutline }

class _ActionButton {
  final String label;
  final VoidCallback onTap;
  final _ActionStyle style;
  _ActionButton({
    required this.label,
    required this.onTap,
    required this.style,
  });
}
