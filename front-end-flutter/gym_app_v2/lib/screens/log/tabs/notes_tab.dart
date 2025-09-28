import 'package:flutter/material.dart';

class NotesTab extends StatefulWidget {
  final String? note;
  final VoidCallback onEdit;
  const NotesTab({super.key, required this.note, required this.onEdit});

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
                        IconButton(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Color(0xFF8854FF),
                            size: 22,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Chỉnh sửa ghi chú',
                          onPressed: widget.onEdit,
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
}
