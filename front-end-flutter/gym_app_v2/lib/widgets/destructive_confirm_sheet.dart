import 'package:flutter/material.dart';
import '../core/extensions/color_extensions.dart';
import 'app_button.dart';
import '../theme/design_tokens.dart';

/// A reusable destructive confirmation bottom sheet used across screens.
/// Return value convention: show it with `showModalBottomSheet<bool>`,
/// and pass `onConfirm: () => Navigator.pop(context, true)` so caller gets true.
class DestructiveConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final Color dangerColor;
  final Color backgroundColor;

  const DestructiveConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel = 'Huỷ',
    this.dangerColor = DesignTokens.danger,
    this.backgroundColor = DesignTokens.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spaceL - 4, // 20
        DesignTokens.spaceM, // 16
        DesignTokens.spaceL - 4,
        DesignTokens.spaceXL, // 32
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacityRatio(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceM - 4),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: DesignTokens.spaceL + 4),
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  label: cancelLabel,
                  onPressed: () => Navigator.pop(context, false),
                  size: AppButtonSize.medium,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceM - 2),
              Expanded(
                child: AppButton.danger(
                  label: confirmLabel,
                  onPressed: onConfirm,
                  size: AppButtonSize.medium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
