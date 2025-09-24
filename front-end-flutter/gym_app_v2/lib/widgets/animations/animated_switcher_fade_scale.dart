import 'package:flutter/material.dart';

/// A reusable AnimatedSwitcher configuration that combines fade + slight scale.
class FadeScaleSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;

  const FadeScaleSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.reverseDuration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: curve,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (widget, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final scale = Tween<double>(begin: 0.95, end: 1).animate(animation);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: widget),
        );
      },
      child: child,
    );
  }
}
