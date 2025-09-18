import 'package:flutter/material.dart';

/// Extension providing compatibility helpers for replacing deprecated Color.withOpacity.
extension ColorOpacityCompat on Color {
  /// Returns a copy of this color with [opacity] (0..1) applied using withValues.
  Color compatOpacity(double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    return withValues(alpha: 255 * clamped);
  }

  /// Multiplies existing alpha by [factor] (0..1) while preserving other channels.
  Color mulAlpha(double factor) {
    final clamped = factor.clamp(0.0, 1.0);
    final newAlpha = a * clamped; // a is 0..1
    return withValues(alpha: newAlpha * 255.0);
  }
}
