import 'package:flutter/material.dart';
import '../repositories/appointments_repository.dart';
import 'app_snack_bar.dart';
import '../theme/design_tokens.dart';

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
  bool _isValid = true; // realtime validity flag
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

    // Attach listeners for realtime validation
    for (final c in [_dayCtrl, _monthCtrl, _yearCtrl, _hourCtrl, _minuteCtrl]) {
      c.addListener(_revalidate);
    }
  }

  @override
  void dispose() {
    for (final c in [_dayCtrl, _monthCtrl, _yearCtrl, _hourCtrl, _minuteCtrl]) {
      c.removeListener(_revalidate);
      c.dispose();
    }
    _noteCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXXL),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spaceM + 2,
            right: DesignTokens.spaceM + 2,
            top: DesignTokens.spaceS + 6,
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                DesignTokens.spaceS +
                4,
          ),
          child: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside input fields
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: DesignTokens.textSecondary.withOpacity(.32),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusS.toDouble(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceM),
                  const Text(
                    'Đặt lịch hẹn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeXL,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceM),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date section with icon and separators
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: DesignTokens.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ngày',
                              style: TextStyle(
                                color: DesignTokens.textSecondary,
                                fontSize: DesignTokens.fontSizeS,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                _dayCtrl,
                                label: 'DD',
                                max: 31,
                              ),
                            ),
                            _buildSeparator('/'),
                            Expanded(
                              child: _numberField(
                                _monthCtrl,
                                label: 'MM',
                                max: 12,
                              ),
                            ),
                            _buildSeparator('/'),
                            Expanded(
                              child: _numberField(
                                _yearCtrl,
                                label: 'YYYY',
                                maxLength: 4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spaceM),
                        // Time section with icon and separators
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: DesignTokens.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Giờ',
                              style: TextStyle(
                                color: DesignTokens.textSecondary,
                                fontSize: DesignTokens.fontSizeS,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                _hourCtrl,
                                label: 'HH',
                                max: 23,
                              ),
                            ),
                            _buildSeparator(':'),
                            Expanded(
                              child: _numberField(
                                _minuteCtrl,
                                label: 'mm',
                                max: 59,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spaceS),
                            Expanded(
                              child: Container(
                                height: DesignTokens.fieldHeight - 4,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusXL,
                                  ),
                                  border: Border.all(
                                    color: DesignTokens.textSecondary
                                        .withOpacity(.25),
                                  ),
                                  color: DesignTokens.textSecondary.withOpacity(
                                    .08,
                                  ),
                                ),
                                child: Text(
                                  '+3h',
                                  style: TextStyle(
                                    color: DesignTokens.textSecondary,
                                    fontSize: DesignTokens.fontSizeS,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spaceMS),
                        _buildDatePreview(),
                      ],
                    ),
                  ),
                  SizedBox(height: DesignTokens.spaceM - 2),
                  _SectionCard(
                    child: Column(
                      children: [
                        _textField(
                          controller: _noteCtrl,
                          label: 'Ghi chú (tuỳ chọn)',
                          maxLines: 2,
                        ),
                        const SizedBox(height: DesignTokens.spaceS + 2),
                        _textField(
                          controller: _locationCtrl,
                          label: 'Địa điểm (tuỳ chọn)',
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: DesignTokens.spaceL - 4),
                  _buildButtons(),
                  SizedBox(height: DesignTokens.spaceS),
                ],
              ),
            ), // Close SingleChildScrollView
          ), // Close GestureDetector
        ), // Close Padding
      ), // Close Container
    ); // Close SafeArea
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
    final invalid = !_isValid;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.textPrimary,
                side: BorderSide(
                  color: DesignTokens.textSecondary.withOpacity(.25),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
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
                backgroundColor: invalid
                    ? DesignTokens.textSecondary.withOpacity(.25)
                    : DesignTokens.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                ),
              ),
              onPressed: creating || invalid ? null : _createAppointment,
              child: creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.textPrimary,
                      ),
                    )
                  : const Text(
                      'Đặt lịch',
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeL - 1,
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
      style: const TextStyle(
        color: DesignTokens.textPrimary,
        fontSize: DesignTokens.fontSizeM,
      ),
      decoration: InputDecoration(
        counterText: '',
        // Use hint instead of floating label to avoid text hugging the border
        hintText: label,
        hintStyle: TextStyle(
          color: DesignTokens.textSecondary.withOpacity(.55),
        ),
        filled: true,
        fillColor: DesignTokens.textSecondary.withOpacity(.12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL - 2),
          borderSide: BorderSide(
            color: DesignTokens.textSecondary.withOpacity(.25),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL - 2),
          borderSide: BorderSide(
            color: DesignTokens.textSecondary.withOpacity(.22),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL - 2),
          borderSide: const BorderSide(color: DesignTokens.brand, width: 1.4),
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
        _revalidate();
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
      style: const TextStyle(
        color: DesignTokens.textPrimary,
        fontSize: DesignTokens.fontSizeM + .2,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: DesignTokens.textSecondary.withOpacity(.55),
        ),
        filled: true,
        fillColor: DesignTokens.textSecondary.withOpacity(.12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL - 2),
          borderSide: BorderSide(
            color: DesignTokens.textSecondary.withOpacity(.25),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL - 2),
          borderSide: BorderSide(
            color: DesignTokens.textSecondary.withOpacity(.22),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL - 2),
          borderSide: const BorderSide(color: DesignTokens.brand, width: 1.4),
        ),
      ),
    );
  }

  void _revalidate() {
    final dt = _parseDateTime();
    final valid =
        dt != null && dt.isAfter(DateTime.now().add(const Duration(hours: 3)));
    if (valid != _isValid) {
      setState(() => _isValid = valid);
    }
  }

  Widget _buildDatePreview() {
    final dt = _parseDateTime();
    if (dt == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Ngày giờ chưa hợp lệ',
          style: TextStyle(
            color: DesignTokens.danger.withOpacity(.8),
            fontSize: DesignTokens.fontSizeS,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final diff = dt.difference(DateTime.now());
    final h = diff.inHours;
    final m = diff.inMinutes - h * 60;
    final timeAway = h >= 1
        ? '${h}h ${m.toString().padLeft(2, '0')}m nữa'
        : '${m} phút nữa';
    return Row(
      children: [
        Icon(
          _isValid ? Icons.check_circle : Icons.error_outline,
          size: 16,
          color: _isValid ? DesignTokens.success : DesignTokens.danger,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _isValid
                ? 'Bắt đầu: ${_friendlyFormat(dt)}  •  Còn $timeAway'
                : 'Phải cách hiện tại ≥ 3 giờ',
            style: TextStyle(
              color: _isValid
                  ? DesignTokens.textSecondary
                  : DesignTokens.danger,
              fontSize: DesignTokens.fontSizeS,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          color: DesignTokens.textSecondary,
          fontSize: DesignTokens.fontSizeL,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _friendlyFormat(DateTime dt) {
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
    const w = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${w[dt.weekday % 7]}, ${dt.day} ${months[dt.month - 1]} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// Reusable section card styled with tokens
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceAlt,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        border: Border.all(color: DesignTokens.textSecondary.withOpacity(.12)),
      ),
      child: child,
    );
  }
}
