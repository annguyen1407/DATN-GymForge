import 'package:flutter/material.dart';

/// Wrap button child content to animate between icon+label and a spinner smoothly.
class LoadingButtonContent extends StatelessWidget {
  final bool loading;
  final String label;
  final IconData? icon;
  final double spinnerSize;
  final TextStyle? labelStyle;

  const LoadingButtonContent({
    super.key,
    required this.loading,
    required this.label,
    this.icon,
    this.spinnerSize = 18,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        labelStyle ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0, .2),
          end: Offset.zero,
        ).animate(anim);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: loading
          ? SizedBox(
              key: const ValueKey('spinner'),
              width: spinnerSize,
              height: spinnerSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(label, style: style),
              ],
            ),
    );
  }
}
