import 'package:flutter/material.dart';

/// Central design tokens for the GymForge app.
///
/// Scope:
/// - Pure value container (no BuildContext usage, no logic branching on theme).
/// - Only static constants; keep it cheap to import anywhere.
/// - Prefer referencing these tokens in new widgets; migrate existing code gradually.
///
/// Migration Strategy (incremental):
/// 1. New components MUST use tokens.
/// 2. When touching an old file, opportunistically swap hard-coded values.
/// 3. Avoid a massive one-shot refactor to keep diffs reviewable.
abstract class DesignTokens {
  // Brand core
  static const Color brand = Color(0xFF8854FF);
  static const Color brandGradientStart = Color(0xFF8854FF);
  static const Color brandGradientEnd = Color(
    0xFF9966FF,
  ); // alias for future theming

  // Semantic
  static const Color danger = Color(0xFFFF4D4D);
  static const Color warning = Color(0xFFFFB020);
  static const Color success = Color(0xFF2ECC71);
  static const Color info = Color(0xFF4098FF);

  // Surfaces
  static const Color bg = Colors.black; // App scaffold background
  static const Color surface = Color(0xFF141414); // Elevated blocks
  static const Color surfaceAlt = Color(0xFF1C1C1E); // Alternate surface
  static const Color surfaceMuted = Color(0xFF222224); // Subtle containers
  static const Color surfaceOutline = Color(0x1FFFFFFF); // Low-contrast border

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB5B5B5);
  static const Color textFaint = Color(0xFF6F6F6F);
  static const Color textInverted = Colors.black;

  // Overlays / states
  static const Color overlayStrong = Color(0xCC000000); // 80% black
  static const Color overlayMedium = Color(0x80000000); // 50%
  static const Color overlayLight = Color(0x33000000); // 20%

  // Spacing scale (4-based rhythm)
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceMS = 12;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 40;

  // Corner radii
  static const double radiusXS = 4;
  static const double radiusS = 6;
  static const double radiusM = 8;
  static const double radiusL = 12;
  static const double radiusXL = 16;
  static const double radiusXXL = 24;

  // Elevation (opacity-based since true Material elevation is minimal in dark design)
  static const double shadowBlurLow = 8;
  static const double shadowBlurMedium = 16;
  static const double shadowBlurHigh = 32;

  // Animation durations
  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 220);
  static const Duration durationSlow = Duration(milliseconds: 360);

  // Opacity (semantic layering)
  static const double disabledOpacity = 0.4;
  static const double focusRingOpacity = 0.9;
  static const double pressedOpacity = 0.85;

  // Typography scale (base 14) - keep numeric only; styles composed elsewhere
  static const double fontSizeXS = 10;
  static const double fontSizeS = 12;
  static const double fontSizeM = 14; // Base
  static const double fontSizeL = 16;
  static const double fontSizeXL = 20;
  static const double fontSizeXXL = 24;
  static const double fontSizeDisplay = 32;

  // Line heights (multipliers)
  static const double lineHeightTight = 1.1;
  static const double lineHeightRegular = 1.3;
  static const double lineHeightRelaxed = 1.5;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandGradientStart, brandGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Button defaults
  static const double buttonHeightSmall = 36;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightLarge = 52;
  static const double buttonIconSize = 20;

  // Form field dimensions
  static const double fieldHeight = 52;
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  // Standard paddings
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceM);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  // Focus ring (conceptual) – define color when implementing focus states
  static const Color focusRingColor = brand;
}

/// Optional semantic helpers (keep lightweight, no context):
abstract class SemanticTokens {
  static const Color successBg = Color(0x1A2ECC71); // 10% alpha success
  static const Color errorBg = Color(0x1AFF4D4D);
  static const Color warningBg = Color(0x1AFFB020);
  static const Color infoBg = Color(0x1A4098FF);
}
