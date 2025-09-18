import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'app_button.dart';

/// Clean rebuilt WorkoutTemplateCard. Previous file was corrupted with duplicates.
class WorkoutTemplateCard extends StatelessWidget {
  final String image;
  final String title;
  final String? tag;
  final int? days;
  final bool showAccept;
  final VoidCallback? onAccept;
  final bool compact;
  final bool dimmed;

  const WorkoutTemplateCard({
    super.key,
    required this.image,
    required this.title,
    this.tag,
    this.days,
    this.showAccept = false,
    this.onAccept,
    this.compact = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) =>
      compact ? _buildCompact(context) : _buildLarge(context);

  Widget _buildCompact(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 3),
    decoration: BoxDecoration(
      color: DesignTokens.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: DesignTokens.surfaceOutline.withOpacity(.35),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          ),
          child: _image(width: 82, height: 82),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: .2,
                    height: 1.15,
                  ),
                ),
                if (days != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$days ngày',
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showAccept)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppButton.danger(
              label: 'Chấp nhận',
              onPressed: onAccept,
              size: AppButtonSize.small,
              fullWidth: false,
            ),
          ),
      ],
    ),
  );

  Widget _buildLarge(BuildContext context) => AspectRatio(
    aspectRatio: 1.8,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DesignTokens.surfaceOutline.withOpacity(.35),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _image()),
          if (dimmed || showAccept)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: DesignTokens.overlayMedium.withOpacity(
                    showAccept ? 0.75 : 0.45,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          if (tag != null)
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _tagColor(tag!),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DesignTokens.surfaceOutline.withOpacity(.25),
                    width: 1,
                  ),
                ),
                child: Text(
                  tag!,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 18,
            bottom: 36,
            right: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: .3,
                    height: 1.12,
                  ),
                ),
                if (days != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$days ngày',
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showAccept)
            Positioned(
              right: 18,
              bottom: 24,
              child: AppButton.danger(
                label: 'Chấp nhận',
                onPressed: onAccept,
                size: AppButtonSize.small,
                fullWidth: false,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _image({double? width, double? height}) {
    if (image.isNotEmpty) {
      return Image.asset(
        image,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _placeholder(width, height),
      );
    }
    return _placeholder(width, height);
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'premium':
        return DesignTokens.warning;
      case 'new':
        return DesignTokens.info;
      default:
        return DesignTokens.danger;
    }
  }

  Widget _placeholder(double? width, double? height) => Container(
    width: width,
    height: height,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          DesignTokens.brandGradientStart,
          DesignTokens.brandGradientEnd,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Icon(
      Icons.image_not_supported_outlined,
      color: Colors.white.withOpacity(.55),
      size: (width ?? 64) * .5,
    ),
  );
}
