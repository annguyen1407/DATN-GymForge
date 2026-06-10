import 'package:flutter/material.dart';
import '../repositories/appointments_repository.dart';
import 'app_snack_bar.dart';

class AppointmentSchedulerBottomSheet extends StatefulWidget {
  final String coachId;
  final String gymerId;
  final List<AppointmentModel> bookedAppointments;
  final VoidCallback? onSuccess;

  const AppointmentSchedulerBottomSheet({
    super.key,
    required this.coachId,
    required this.gymerId,
    required this.bookedAppointments,
    this.onSuccess,
  });

  @override
  State<AppointmentSchedulerBottomSheet> createState() =>
      _AppointmentSchedulerBottomSheetState();

  /// Static method to show the bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required String coachId,
    required String gymerId,
    required List<AppointmentModel> bookedAppointments,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppointmentSchedulerBottomSheet(
        coachId: coachId,
        gymerId: gymerId,
        bookedAppointments: bookedAppointments,
        onSuccess: onSuccess,
      ),
    );
  }
}

class _AppointmentSchedulerBottomSheetState
    extends State<AppointmentSchedulerBottomSheet> {
  final _appointmentsRepo = AppointmentsRepository();
  // Numeric input fields instead of calendar + grid
  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _hourCtrl = TextEditingController();
  final _minuteCtrl = TextEditingController(text: '00');
  bool creating = false;
  final _noteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 3));
    final base = DateTime(now.year, now.month, now.day, now.hour + 1);
    _dayCtrl.text = base.day.toString().padLeft(2, '0');
    _monthCtrl.text = base.month.toString().padLeft(2, '0');
    _yearCtrl.text = base.year.toString();
    _hourCtrl.text = base.hour.toString().padLeft(2, '0');
    _minuteCtrl.text = '00';
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _noteCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Set<DateTime> get bookedDates {
    return widget.bookedAppointments
        .where((a) => a.date != null)
        .map((a) => DateTime(a.date!.year, a.date!.month, a.date!.day))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111113),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Đặt lịch hẹn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Date & Time block
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(_dayCtrl, label: 'DD', max: 31),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _numberField(
                              _monthCtrl,
                              label: 'MM',
                              max: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _numberField(
                              _yearCtrl,
                              label: 'YYYY',
                              maxLength: 4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(
                              _hourCtrl,
                              label: 'HH',
                              max: 23,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _numberField(
                              _minuteCtrl,
                              label: 'mm',
                              max: 59,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.18),
                                ),
                                color: Colors.white.withOpacity(.04),
                              ),
                              child: Text(
                                '+3h',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Extra info block
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(.08)),
                  ),
                  child: Column(
                    children: [
                      _textField(
                        controller: _noteCtrl,
                        label: 'Ghi chú (tuỳ chọn)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      _textField(
                        controller: _locationCtrl,
                        label: 'Địa điểm (tuỳ chọn)',
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildButtons(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createAppointment() async {
    if (creating) return;
    final parsed = _parseDateTime();
    if (parsed == null) {
      AppSnackBar.showError(context, 'Ngày giờ không hợp lệ');
      return;
    }
    final now = DateTime.now();
    if (parsed.isBefore(now.add(const Duration(hours: 3)))) {
      AppSnackBar.showError(context, 'Phải cách hiện tại ít nhất 3 giờ');
      return;
    }
    setState(() => creating = true);

    AppSnackBar.showInfo(context, 'Đang tạo lịch hẹn...');

    try {
      final created = await _appointmentsRepo.create(
        gymerId: widget.gymerId,
        coachId: widget.coachId,
        date: parsed,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
      );

      if (!mounted) return;

      if (created != null) {
        AppSnackBar.showSuccess(context, 'Đặt lịch thành công');
        widget.onSuccess?.call();
        Navigator.pop(context, true);
      } else {
        AppSnackBar.showError(context, 'Không tạo được lịch, thử lại');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Lỗi kết nối, thử lại');
    } finally {
      if (mounted) {
        setState(() => creating = false);
      }
    }
  }

  DateTime? _parseDateTime() {
    int? day = int.tryParse(_dayCtrl.text);
    int? month = int.tryParse(_monthCtrl.text);
    int? year = int.tryParse(_yearCtrl.text);
    int? hour = int.tryParse(_hourCtrl.text);
    int? minute = int.tryParse(_minuteCtrl.text);
    if (day == null ||
        month == null ||
        year == null ||
        hour == null ||
        minute == null) {
      return null;
    }
    if (day < 1 ||
        day > 31 ||
        month < 1 ||
        month > 12 ||
        year < DateTime.now().year ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    try {
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(.25)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: creating ? null : () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2DE2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: creating ? null : _createAppointment,
              child: creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Đặt lịch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(
    TextEditingController c, {
    required String label,
    int? max,
    int? maxLength,
  }) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      maxLength: maxLength ?? 2,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(.55)),
        filled: true,
        fillColor: Colors.white.withOpacity(.07),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(.18),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(.18),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8E2DE2), width: 1.4),
        ),
      ),
      onChanged: (val) {
        if (max != null) {
          final v = int.tryParse(val);
          if (v != null && v > max) {
            c.text = max.toString().padLeft(2, '0');
            c.selection = TextSelection.fromPosition(
              TextPosition(offset: c.text.length),
            );
          }
        }
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14.2),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(.55)),
        filled: true,
        fillColor: Colors.white.withOpacity(.07),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(.18),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(.18),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8E2DE2), width: 1.4),
        ),
      ),
    );
  }
}
