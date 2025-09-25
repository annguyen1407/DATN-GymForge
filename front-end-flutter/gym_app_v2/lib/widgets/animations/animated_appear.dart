import 'package:flutter/material.dart';

/// A lightweight fade + slide in animation wrapper.
/// Usage: wrap any child that should smoothly appear on first build.
class AnimatedAppear extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double dy; // vertical offset (from below)
  final double dx; // horizontal offset
  final bool enable;

  const AnimatedAppear({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.dy = 12,
    this.dx = 0,
    this.enable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enable) return child;
    // Manually implement delay by starting at 0 then triggering rebuild with animation start.
    return _DelayedTween(
      delay: delay,
      duration: duration,
      curve: curve,
      builder: (value) {
        final opacity = value;
        final offsetY = (1 - value) * dy;
        final offsetX = (1 - value) * dx;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: child,
          ),
        );
      },
    );
  }
}

class _DelayedTween extends StatefulWidget {
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Widget Function(double value) builder;
  const _DelayedTween({
    required this.delay,
    required this.duration,
    required this.curve,
    required this.builder,
  });

  @override
  State<_DelayedTween> createState() => _DelayedTweenState();
}

class _DelayedTweenState extends State<_DelayedTween>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _controller, curve: widget.curve);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => widget.builder(_anim.value),
    );
  }
}
