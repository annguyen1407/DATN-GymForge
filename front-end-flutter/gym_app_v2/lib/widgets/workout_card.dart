// Dùng ở: workout_screen tab "Kế hoạch" và "Chuyên gia". Card hiển thị workout chung.
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../core/extensions/color_extensions.dart';
import 'plan_type_badge.dart';

// NOTE: Legacy color mapping removed. Now gradients derive from PlanTypeBadge.baseColor

/// WorkoutCard: Card hiển thị workout chung cho tab "Kế hoạch" và "Chuyên gia"
/// Khác với WorkoutTemplateCard (dùng riêng cho tab "Khám phá")
class WorkoutCard extends StatelessWidget {
  final String image; // asset path (có thể rỗng)
  final String title;
  final String? description;
  final String? subtitle; // ví dụ số ngày / tác giả
  final String? badge; // planType hoặc trạng thái
  final Color? badgeColor;
  final List<String>? tags;
  final VoidCallback? onTap;
  final String? planType; // thêm để map màu & placeholder
  // Khi dùng trong horizontal carousel cần card thấp hơn -> compact=true
  final bool compact;

  const WorkoutCard({
    required this.image,
    required this.title,
    this.description,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.tags,
    this.onTap,
    this.planType,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final accent = badgeColor ?? PlanTypeBadge.baseColor(planType ?? badge);
    const knownAssets = {
      'assets/images/onboarding_1.png',
      'assets/images/onboarding_2.png',
      'assets/images/onboarding_3.png',
      'assets/images/welcome_bg.png',
    };
    final imageHeight = compact ? 110.0 : 140.0;
    // Determine if we treat the provided image as a network image or an allowed asset
    final isNetwork =
        image.startsWith('http://') || image.startsWith('https://');
    final isAsset =
        !isNetwork && image.isNotEmpty && knownAssets.contains(image);
    // Build placeholder gradient container
    Widget placeholder() => Container(
      width: double.infinity,
      height: imageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacityRatio(.55),
            Colors.black.withOpacityRatio(.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.fitness_center,
        color: Colors.white.withOpacityRatio(.4),
        size: 48,
      ),
    );
    // Choose image widget
    Widget imageWidget;
    if (isNetwork) {
      imageWidget = Image.network(
        image,
        width: double.infinity,
        height: imageHeight,
        fit: BoxFit.cover,
        // While loading show subtle fade placeholder
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            children: [
              placeholder(),
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) => placeholder(),
      );
    } else if (isAsset) {
      imageWidget = Image.asset(
        image,
        width: double.infinity,
        height: imageHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder(),
      );
    } else {
      imageWidget = placeholder();
    }
    final padTop = compact ? 12.0 : 14.0;
    final padBottom = compact ? 12.0 : 16.0;
    final titleSize = compact ? 16.0 : 17.0;
    final descLines = compact ? 1 : 2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 0 : 16),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DesignTokens.surfaceOutline.withOpacityRatio(.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacityRatio(.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  imageWidget,
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacityRatio(0.06),
                            Colors.black.withOpacityRatio(0.60),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: PlanTypeBadge(
                        planType: planType ?? badge,
                        dense: true,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, padTop, 16, padBottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: titleSize,
                      letterSpacing: .2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description!,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: descLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (!compact && tags != null && tags!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: tags!
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.surfaceOutline
                                    .withOpacityRatio(.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: DesignTokens.surfaceOutline
                                      .withOpacityRatio(.35),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: DesignTokens.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
