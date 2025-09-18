import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Unified styled snackbar helper with variants.
/// Usage:
///   AppSnackBar.showSuccess(context, 'Saved');
///   AppSnackBar.showError(context, 'Failed');
class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarVariant variant = SnackBarVariant.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = _variantTheme(variant);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          duration: duration,
          content: _SnackContent(
            icon: theme.icon,
            message: message,
            bg: theme.bg,
            border: theme.border,
            fg: theme.fg,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ),
      );
  }

  static void showSuccess(BuildContext c, String m) =>
      show(c, message: m, variant: SnackBarVariant.success);
  static void showError(BuildContext c, String m) =>
      show(c, message: m, variant: SnackBarVariant.error);
  static void showInfo(BuildContext c, String m) =>
      show(c, message: m, variant: SnackBarVariant.info);
  static void showWarning(BuildContext c, String m) =>
      show(c, message: m, variant: SnackBarVariant.warning);
}

enum SnackBarVariant { success, error, info, warning }

class _VariantTheme {
  final Color bg;
  final Color border;
  final Color fg;
  final IconData icon;
  const _VariantTheme({
    required this.bg,
    required this.border,
    required this.fg,
    required this.icon,
  });
}

_VariantTheme _variantTheme(SnackBarVariant v) {
  switch (v) {
    case SnackBarVariant.success:
      return _VariantTheme(
        bg: const Color(0xFF10351F),
        border: const Color(0xFF2E7D32),
        fg: const Color(0xFF7EE2A8),
        icon: Icons.check_circle_outline,
      );
    case SnackBarVariant.error:
      return _VariantTheme(
        bg: const Color(0xFF3A1216),
        border: const Color(0xFFD32F2F),
        fg: const Color(0xFFFF8A80),
        icon: Icons.error_outline,
      );
    case SnackBarVariant.warning:
      return _VariantTheme(
        bg: const Color(0xFF3A2F10),
        border: const Color(0xFFF9A825),
        fg: const Color(0xFFFFE082),
        icon: Icons.warning_amber_rounded,
      );
    case SnackBarVariant.info:
      return _VariantTheme(
        bg: const Color(0xFF183045),
        border: const Color(0xFF0288D1),
        fg: const Color(0xFF81D4FA),
        icon: Icons.info_outline,
      );
  }
}

class _SnackContent extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color bg;
  final Color border;
  final Color fg;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SnackContent({
    required this.icon,
    required this.message,
    required this.bg,
    required this.border,
    required this.fg,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM - 4, // 12
        vertical: DesignTokens.spaceS - 2, // 6
      ),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceM - 2, // 14
        DesignTokens.spaceS + 4, // 12
        DesignTokens.spaceM - 2,
        DesignTokens.spaceS + 4,
      ),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: DesignTokens.spaceM - 4),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.25,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: fg,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
