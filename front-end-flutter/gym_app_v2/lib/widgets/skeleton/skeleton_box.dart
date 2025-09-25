import 'package:flutter/material.dart';

/// Lightweight skeleton box with optional shimmer (disabled by default for performance).
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool shimmer;
  final Color? color;
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shimmer = false,
    this.color,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.shimmer) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Colors.grey[800]!;
    if (!widget.shimmer || _controller == null) {
      return _buildStatic(baseColor);
    }
    return AnimatedBuilder(
      animation: _controller!,
      builder: (_, __) {
        final t = _controller!.value;
        final highlight = Colors.grey[700]!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: [baseColor, highlight, baseColor],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatic(Color color) => Container(
    width: widget.width,
    height: widget.height,
    decoration: BoxDecoration(color: color, borderRadius: widget.borderRadius),
  );
}
