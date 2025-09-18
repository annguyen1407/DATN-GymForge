import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// A reusable, design-token driven date picker presented as a bottom sheet
/// returning a DateTime the user confirms, or null if cancelled.
/// Use: final picked = await AppDatePicker.show(context, initialDate: ...);
class AppDatePicker {
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Chọn ngày',
    bool hideTitle = false,
    String confirmLabel = 'Lưu',
    String cancelLabel = 'Huỷ',
    bool showTodayShortcut = true,
    bool compact = false,
    bool disablePast = false,
  }) async {
    final now = DateTime.now();
    DateTime temp = initialDate ?? DateTime(now.year, now.month, now.day);
    final DateTime minDate = firstDate ?? DateTime(now.year - 70);
    final DateTime maxDate = lastDate ?? DateTime(now.year + 2);
    final todayStart = DateTime(now.year, now.month, now.day);
    // When disablePast is true, clamp minDate to today.
    final effectiveMinDate = disablePast && minDate.isBefore(todayStart)
        ? todayStart
        : minDate;
    if (disablePast && temp.isBefore(effectiveMinDate)) {
      temp = effectiveMinDate;
    }
    if (compact) {
      // Dialog style compact popup
      return showDialog<DateTime>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 40,
          ),
          child: _DatePickerSheet(
            title: title,
            hideTitle: hideTitle,
            initial: temp,
            minDate: effectiveMinDate,
            maxDate: maxDate,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            showTodayShortcut: showTodayShortcut,
            compact: true,
            disablePast: disablePast,
          ),
        ),
      );
    }

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DatePickerSheet(
        title: title,
        hideTitle: hideTitle,
        initial: temp,
        minDate: effectiveMinDate,
        maxDate: maxDate,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        showTodayShortcut: showTodayShortcut,
        compact: false,
        disablePast: disablePast,
      ),
    );
  }

  /// Convenience for compact dialog presentation.
  static Future<DateTime?> showCompact(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Chọn ngày',
    bool hideTitle = false,
    String confirmLabel = 'Lưu',
    String cancelLabel = 'Huỷ',
    bool showTodayShortcut = true,
    bool disablePast = false,
  }) => show(
    context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    title: title,
    hideTitle: hideTitle,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    showTodayShortcut: showTodayShortcut,
    compact: true,
    disablePast: disablePast,
  );
}

class _DatePickerSheet extends StatefulWidget {
  final DateTime initial;
  final DateTime minDate;
  final DateTime maxDate;
  final String title;
  final bool hideTitle;
  final String confirmLabel;
  final String cancelLabel;
  final bool showTodayShortcut;
  final bool compact;
  final bool disablePast;

  const _DatePickerSheet({
    required this.initial,
    required this.minDate,
    required this.maxDate,
    required this.title,
    required this.hideTitle,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.showTodayShortcut,
    required this.compact,
    required this.disablePast,
  });

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _selected;
  late DateTime _visibleMonth; // first day of visible month
  _PickerViewMode _viewMode = _PickerViewMode.day;

  static const List<String> _weekdayShort = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  @override
  void initState() {
    super.initState();
    _selected = _clampDate(widget.initial);
    _visibleMonth = DateTime(_selected.year, _selected.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isCompact = widget.compact;
    return SafeArea(
      top: false,
      child: Padding(
        padding: media.viewInsets,
        child: Container(
          constraints: isCompact
              ? BoxConstraints(
                  minHeight: widget.hideTitle ? 300 : 330,
                  maxWidth: 380,
                )
              : BoxConstraints(maxHeight: widget.hideTitle ? 400 : 430),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DesignTokens.surfaceAlt, DesignTokens.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: isCompact
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: DesignTokens.surfaceOutline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: isCompact ? 24 : 32,
                offset: Offset(0, isCompact ? 10 : 18),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(14, isCompact ? 10 : 10, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompact) ...[_grabber(), const SizedBox(height: 4)],
              _headerBar(),
              const SizedBox(height: 4),
              _weekdayRow(),
              const SizedBox(height: 4),
              if (isCompact)
                SizedBox(
                  height: widget.hideTitle ? 190 : 200,
                  child: _calendarBody(),
                )
              else
                Flexible(child: _calendarBody()),
              const SizedBox(height: 4),
              _actionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendarBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide =
            Tween<Offset>(
              begin: const Offset(0, .05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _viewMode == _PickerViewMode.day
          ? KeyedSubtree(key: const ValueKey('dayView'), child: _dayGrid())
          : KeyedSubtree(
              key: const ValueKey('monthYearView'),
              child: _monthYearGrid(),
            ),
    );
  }

  Widget _grabber() => Container(
    width: 48,
    height: 5,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(3),
    ),
  );

  Widget _headerBar() {
    final monthLabel = _formatMonth(_visibleMonth);
    final bool canGoPrev = _canGoPrevMonth();
    return Row(
      children: [
        if (!widget.hideTitle)
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeM + 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (widget.showTodayShortcut)
          TextButton(
            onPressed: () => setState(() {
              final now = DateTime.now();
              _selected = _clampDate(now);
              _visibleMonth = DateTime(_selected.year, _selected.month, 1);
            }),
            child: const Text(
              'Hôm nay',
              style: TextStyle(color: DesignTokens.brand),
            ),
          ),
        const SizedBox(width: 6),
        _navButton(
          Icons.chevron_left,
          canGoPrev ? _prevMonth : null,
          disabled: !canGoPrev,
        ),
        const SizedBox(width: 2),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _toggleMonthYearMode,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Text(
                  monthLabel,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: DesignTokens.fontSizeS + 1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _viewMode == _PickerViewMode.monthYear ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more,
                    size: 16,
                    color: DesignTokens.textSecondary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        _navButton(Icons.chevron_right, _nextMonth),
      ],
    );
  }

  void _toggleMonthYearMode() {
    setState(() {
      _viewMode = _viewMode == _PickerViewMode.day
          ? _PickerViewMode.monthYear
          : _PickerViewMode.day;
    });
  }

  Widget _weekdayRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          return Expanded(
            child: Center(
              child: Text(
                _weekdayShort[i],
                style: const TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _dayGrid() {
    final days = _buildVisibleCurrentMonthDays(_visibleMonth);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final rowCount = (days.length / 7).ceil();
        final cellHeight = (constraints.maxHeight) / rowCount.clamp(1, 6);
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: (constraints.maxWidth / 7) / cellHeight,
          ),
          itemCount: days.length,
          itemBuilder: (ctx, index) {
            final day = days[index];
            final isCurrentMonth =
                day != null && day.month == _visibleMonth.month;
            final todayStart = DateTime.now();
            final today = DateTime(
              todayStart.year,
              todayStart.month,
              todayStart.day,
            );
            final bool isPastByRule =
                day != null && widget.disablePast && day.isBefore(today);
            final isDisabled =
                day == null ||
                day.isBefore(widget.minDate) ||
                day.isAfter(widget.maxDate) ||
                isPastByRule;
            final isSelected = day != null && _isSameDay(day, _selected);
            final isToday = day != null && _isSameDay(day, today);
            final bool isWeekend =
                day != null &&
                (day.weekday == DateTime.saturday ||
                    day.weekday == DateTime.sunday);

            Color? textColor;
            if (day == null) {
              textColor = null;
            } else if (isDisabled) {
              textColor = DesignTokens.textFaint.withOpacity(0.35);
            } else if (isSelected) {
              textColor = DesignTokens.textInverted;
            } else if (isToday) {
              textColor = DesignTokens.brand;
            } else {
              textColor = isWeekend
                  ? DesignTokens.textSecondary
                  : DesignTokens.textPrimary;
            }

            BoxDecoration? deco;
            if (isSelected) {
              deco = BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    DesignTokens.brandGradientStart,
                    DesignTokens.brandGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.brand.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              );
            } else if (isToday) {
              deco = BoxDecoration(
                border: Border.all(
                  color: DesignTokens.brand.withOpacity(0.6),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(12),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: isDisabled ? 0.40 : 1,
                child: _DaySelectable(
                  isDisabled: isDisabled || !isCurrentMonth,
                  isSelected: isSelected,
                  decoration: deco,
                  onTap: () {
                    if (day == null) return;
                    setState(() => _selected = day);
                  },
                  child: day == null
                      ? const SizedBox.shrink()
                      : Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _monthYearGrid() {
    final year = _visibleMonth.year;
    final minYear = widget.minDate.year;
    final maxYear = widget.maxDate.year;
    final now = DateTime.now();
    final todayYear = now.year;
    final todayMonth = now.month;

    final canPrevYear =
        year > minYear && (!widget.disablePast || year > todayYear);
    final canNextYear = year < maxYear;

    return Column(
      key: const ValueKey('monthYear'),
      children: [
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _navButton(
              Icons.chevron_left,
              canPrevYear ? _prevYear : null,
              disabled: !canPrevYear,
            ),
            const SizedBox(width: 8),
            Text(
              '$year',
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            _navButton(
              Icons.chevron_right,
              canNextYear ? _nextYear : null,
              disabled: !canNextYear,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final cellW = constraints.maxWidth / 3;
              final cellH = constraints.maxHeight / 4;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: cellW / cellH,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: 12,
                itemBuilder: (ctx, i) {
                  final monthIndex = i + 1;
                  final firstDay = DateTime(year, monthIndex, 1);
                  final lastDay = DateTime(year, monthIndex + 1, 0);
                  bool disabled =
                      firstDay.isBefore(widget.minDate) ||
                      lastDay.isAfter(widget.maxDate);
                  if (widget.disablePast &&
                      year == todayYear &&
                      monthIndex < todayMonth) {
                    disabled = true;
                  }
                  final isCurrentVisible =
                      monthIndex == _visibleMonth.month &&
                      year == _visibleMonth.year;
                  final isCurrentRealMonth =
                      monthIndex == todayMonth && year == todayYear;

                  BoxDecoration? deco;
                  if (isCurrentVisible) {
                    deco = BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DesignTokens.brandGradientStart,
                          DesignTokens.brandGradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    );
                  } else if (isCurrentRealMonth) {
                    deco = BoxDecoration(
                      border: Border.all(
                        color: DesignTokens.brand.withOpacity(0.6),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    );
                  }

                  final label = 'Tháng $monthIndex';
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: disabled ? 0.35 : 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: disabled
                          ? null
                          : () {
                              setState(() {
                                // Keep same day if possible, else clamp to last day of new month.
                                final desiredDay = _selected.day;
                                final lastDayOfTarget = DateTime(
                                  year,
                                  monthIndex + 1,
                                  0,
                                ).day;
                                final newDay = desiredDay <= lastDayOfTarget
                                    ? desiredDay
                                    : lastDayOfTarget;
                                _visibleMonth = DateTime(year, monthIndex, 1);
                                final tentative = DateTime(
                                  year,
                                  monthIndex,
                                  newDay,
                                );
                                _selected = _clampDate(tentative);
                                _viewMode = _PickerViewMode.day;
                              });
                            },
                      child: Container(
                        decoration: deco,
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: deco != null
                                ? DesignTokens.textInverted
                                : DesignTokens.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .15,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Old _buildMonthDays removed (replaced by _buildVisibleCurrentMonthDays)

  /// Build only current month days aligned with weekday start.
  /// Returns a list sized (weekCount * 7) where placeholder empty cells are null.
  List<DateTime?> _buildVisibleCurrentMonthDays(DateTime monthStart) {
    final first = DateTime(monthStart.year, monthStart.month, 1);
    final total = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final firstWeekday = first.weekday; // 1=Mon ..7=Sun
    final leadingEmpty = firstWeekday - 1; // number of blanks before day 1
    final List<DateTime?> cells = List.filled(
      leadingEmpty,
      null,
      growable: true,
    );
    for (int d = 1; d <= total; d++) {
      cells.add(DateTime(monthStart.year, monthStart.month, d));
    }
    // Pad tail to complete final week only (no fixed 6 rows requirement)
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  Widget _navButton(
    IconData icon,
    VoidCallback? onTap, {
    bool disabled = false,
  }) {
    final Color baseColor = Colors.white.withOpacity(0.07);
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
          color: disabled ? baseColor.withOpacity(0.15) : baseColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(disabled ? 0.04 : 0.08),
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 20,
          color: disabled
              ? DesignTokens.textSecondary.withOpacity(0.35)
              : DesignTokens.textSecondary,
        ),
      ),
    );
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  void _prevYear() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year - 1, _visibleMonth.month, 1);
    });
  }

  void _nextYear() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year + 1, _visibleMonth.month, 1);
    });
  }

  bool _canGoPrevMonth() {
    if (!widget.disablePast) return true;
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    return _visibleMonth.isAfter(currentMonthStart);
  }

  String _formatMonth(DateTime d) {
    const months = [
      '01',
      '02',
      '03',
      '04',
      '05',
      '06',
      '07',
      '08',
      '09',
      '10',
      '11',
      '12',
    ];
    return '${months[d.month - 1]}/${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _clampDate(DateTime d) {
    if (d.isBefore(widget.minDate)) return widget.minDate;
    if (d.isAfter(widget.maxDate)) return widget.maxDate;
    return d;
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.textSecondary,
              side: BorderSide(color: Colors.white.withOpacity(0.10)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(widget.cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(context, _selected),
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}

enum _PickerViewMode { day, monthYear }

/// Internal selectable day cell with scale + subtle pulse animation when selected.
class _DaySelectable extends StatefulWidget {
  final bool isDisabled;
  final bool isSelected;
  final BoxDecoration? decoration;
  final VoidCallback onTap;
  final Widget child;

  const _DaySelectable({
    required this.isDisabled,
    required this.isSelected,
    required this.decoration,
    required this.onTap,
    required this.child,
  });

  @override
  State<_DaySelectable> createState() => _DaySelectableState();
}

class _DaySelectableState extends State<_DaySelectable>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _DaySelectable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      // brief tap pulse
      _c.forward(from: 0).then((_) => _c.reverse());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOut,
      decoration: widget.decoration,
      alignment: Alignment.center,
      child: widget.child,
    );
    return ScaleTransition(
      scale: widget.isSelected ? _scale : const AlwaysStoppedAnimation(1),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: content,
      ),
    );
  }
}
