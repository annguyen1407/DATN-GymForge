import 'package:flutter/material.dart';

/// A reusable expandable/collapsible body text widget used for long
/// description / instruction sections. If the text does not exceed
/// [trimLines], it renders plainly without a toggle.
class ExpandableBodyText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int trimLines;
  final String expandLabel;
  final String collapseLabel;
  final Duration animationDuration;
  final Curve animationCurve;

  const ExpandableBodyText({
    super.key,
    required this.text,
    this.style,
    this.trimLines = 6,
    this.expandLabel = 'Xem thêm',
    this.collapseLabel = 'Thu gọn',
    this.animationDuration = const Duration(milliseconds: 220),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<ExpandableBodyText> createState() => _ExpandableBodyTextState();
}

class _ExpandableBodyTextState extends State<ExpandableBodyText>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _overflow = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measureOverflow();
  }

  @override
  void didUpdateWidget(covariant ExpandableBodyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.trimLines != widget.trimLines) {
      _measureOverflow();
    }
  }

  void _measureOverflow() {
    // Use TextPainter to detect if text exceeds trimLines
    final span = TextSpan(text: widget.text, style: widget.style);
    final tp = TextPainter(
      text: span,
      maxLines: widget.trimLines,
      textDirection: TextDirection.ltr,
    );
    tp.layout(
      maxWidth: MediaQuery.of(context).size.width - 32,
    ); // padding heuristic
    final overflow = tp.didExceedMaxLines;
    if (_overflow != overflow) {
      setState(() => _overflow = overflow);
    }
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.45);

    if (!_overflow) {
      return Text(widget.text, style: style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          child: Stack(
            children: [
              Text(
                widget.text,
                style: style,
                maxLines: _expanded ? null : widget.trimLines,
                overflow: TextOverflow.fade,
              ),
              if (!_expanded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xAA0B0C0E)],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? widget.collapseLabel : widget.expandLabel,
                style: const TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                duration: widget.animationDuration,
                turns: _expanded ? 0.5 : 0.0,
                curve: widget.animationCurve,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.pinkAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
