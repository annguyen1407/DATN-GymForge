import 'package:flutter/material.dart';

/// Color opacity helpers replacing deprecated withOpacity usages.
/// We deliberately avoid calling the deprecated API anywhere so lints disappear.
extension ColorOpacityCompat on Color {
  /// Applies an absolute opacity ratio (0..1) replacing the entire alpha channel.
  Color withOpacityRatio(double ratio) {
    final r = ratio.clamp(0.0, 1.0);
    return withValues(alpha: r);
  }

  /// Multiplies existing alpha by [factor] (0..1) preserving other channels.
  Color mulAlpha(double factor) {
    final f = factor.clamp(0.0, 1.0);
    return withValues(alpha: a * f); // 'a' getter already 0..1
  }

  /// Backwards compatibility name used earlier in the refactor.
  Color compatOpacity(double ratio) => withOpacityRatio(ratio);
}
