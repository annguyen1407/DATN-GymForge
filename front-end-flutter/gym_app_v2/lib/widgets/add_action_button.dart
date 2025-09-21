import 'package:flutter/material.dart';
import '../core/extensions/color_extensions.dart';
import '../theme/design_tokens.dart';

/// AddActionButton: Unified "+" action entry point used across the app.
///
/// Use cases:
/// - Floating circular add (overlay in lists / detail screens)
/// - Inline pill ("Thêm ngày tập luyện")
/// - Full-width bar style (delegated to AppButton if large CTA)
///
/// Variants intentionally minimal to avoid fragmentation; leverage existing
/// AppButton for large/primary flows.
class AddActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String? label;
  final AddActionButtonStyle style;
  final String? tooltip;
  final bool enabled;

  const AddActionButton.circle({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.tooltip,
  }) : label = null,
       style = AddActionButtonStyle.circle,
       enabled = onPressed != null && !loading;

  const AddActionButton.pill({
    super.key,
    required this.onPressed,
    this.label,
    this.loading = false,
    this.tooltip,
  }) : style = AddActionButtonStyle.pill,
       enabled = onPressed != null && !loading;

  const AddActionButton.outlinePill({
    super.key,
    required this.onPressed,
    this.label,
    this.loading = false,
    this.tooltip,
  }) : style = AddActionButtonStyle.outlinePill,
       enabled = onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    Widget inner;
    switch (style) {
      case AddActionButtonStyle.circle:
        inner = _buildCircle(context);
        break;
      case AddActionButtonStyle.pill:
      case AddActionButtonStyle.outlinePill:
        inner = _buildPill(
          context,
          outline: style == AddActionButtonStyle.outlinePill,
        );
        break;
    }
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: inner);
    }
    return inner;
  }

  Widget _buildCircle(BuildContext context) {
    final disabled = !enabled;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: disabled ? 0.5 : 1,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: disabled
                ? LinearGradient(colors: [Colors.grey[800]!, Colors.grey[700]!])
                : DesignTokens.brandGradient,
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: DesignTokens.brand.withOpacityRatio(.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, {required bool outline}) {
    final disabled = !enabled;
    final effectiveLabel = label ?? 'Thêm';
    final gradient = DesignTokens.brandGradient;
    final bg = outline ? Colors.transparent : DesignTokens.surfaceAlt;
    final border = outline ? Border.all(color: Colors.white24, width: 1) : null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: outline ? null : bg,
            border: border,
            gradient: outline ? null : gradient,
            boxShadow: disabled || outline
                ? []
                : [
                    BoxShadow(
                      color: DesignTokens.brand.withOpacityRatio(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!loading) ...[
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 6),
              ],
              loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      effectiveLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AddActionButtonStyle { circle, pill, outlinePill }
