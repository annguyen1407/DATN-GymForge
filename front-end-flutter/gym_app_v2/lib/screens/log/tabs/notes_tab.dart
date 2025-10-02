import 'package:flutter/material.dart';
import '../../../repositories/exercise_log_repository.dart';
import '../../../services/api_constants.dart';

class NotesTab extends StatefulWidget {
  final String? note;
  final ValueChanged<String?> onEdit; // returns updated note (null if cleared)
  final DateTime date; // date context from LogOfDayScreen
  const NotesTab({
    super.key,
    required this.note,
    required this.onEdit,
    required this.date,
  });

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  bool _expanded = false;

  bool _isLong(String text, TextStyle style, double maxWidth, int maxLines) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = widget.note != null && widget.note!.trim().isNotEmpty;
    final text = hasNote ? widget.note!.trim() : 'Chưa có ghi chú cho ngày này';
    final style = TextStyle(
      color: hasNote ? Colors.white : Colors.white54,
      fontSize: 14,
      height: 1.35,
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final long =
                  hasNote && _isLong(text, style, constraints.maxWidth, 5);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      child: Text(
                        text,
                        style: style,
                        maxLines: !_expanded && long ? 5 : null,
                        overflow: !_expanded && long
                            ? TextOverflow.fade
                            : TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (long)
                          GestureDetector(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _expanded ? 'Thu gọn' : 'Xem thêm',
                                style: const TextStyle(
                                  color: Color(0xFF8854FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 24),
                        _EditButton(
                          onTap: () =>
                              _openEdit(context, initial: widget.note ?? ''),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context, {
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial.trim());
    final focusNode = FocusNode();
    final repo = ExerciseLogRepository(baseUrl: ApiConstants.baseUrl);
    bool saving = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121214).withOpacity(0.98),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 40,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: StatefulBuilder(
                builder: (ctx, setSheetState) {
                  Future<void> save() async {
                    if (saving) return;
                    final value = controller.text.trim();
                    setSheetState(() => saving = true);
                    final ok = await repo.updateMyDailyLogNote(
                      date: widget.date,
                      note: value,
                    );
                    if (!ctx.mounted) return;
                    setSheetState(() => saving = false);
                    if (ok) {
                      Navigator.pop(ctx, value);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Lưu ghi chú thất bại')),
                      );
                    }
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chỉnh sửa ghi chú',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1F24),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          maxLines: 6,
                          minLines: 3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập ghi chú...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                            ),
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Chỉ lưu nội dung – có thể sửa bất kỳ lúc nào.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Huỷ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: saving ? null : save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8854FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Lưu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    ).then((value) {
      if (value is String) {
        final trimmed = value.trim();
        // Propagate new value (null if empty to indicate deletion)
        widget.onEdit(trimmed.isEmpty ? null : trimmed);
        setState(() {}); // local rebuild just in case note shown directly
      }
    });
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2B31),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.edit_outlined,
          size: 18,
          color: Color(0xFF8854FF),
        ),
      ),
    );
  }
}
