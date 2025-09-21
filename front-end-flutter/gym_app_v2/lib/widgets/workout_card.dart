// Dùng ở: workout_screen tab "Kế hoạch" và "Chuyên gia". Card hiển thị workout chung.
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../core/extensions/color_extensions.dart';

/// Màu theo planType để hiển thị badge & gradient khi thiếu ảnh
Color _planTypeColor(String? planType) {
  switch (planType) {
    case 'STRENGTH':
      return DesignTokens.danger;
    case 'CARDIO':
      return DesignTokens.warning;
    case 'FLEXIBILITY':
      return DesignTokens.success;
    case 'COMBINED':
      return DesignTokens.brand;
    default:
      return DesignTokens.info;
  }
}

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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final accent = badgeColor ?? _planTypeColor(planType ?? badge);
    // Danh sách asset hiện có để tránh load asset không tồn tại (giảm spam error log)
    const knownAssets = {
      'assets/images/onboarding_1.png',
      'assets/images/onboarding_2.png',
      'assets/images/onboarding_3.png',
      'assets/images/welcome_bg.png',
    };
    final effectiveImage = (image.isNotEmpty && knownAssets.contains(image))
        ? image
        : ''; // nếu không thuộc danh sách -> dùng placeholder gradient

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Phần ảnh header
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  // Ảnh hoặc placeholder gradient
                  if (effectiveImage.isNotEmpty)
                    Image.asset(
                      effectiveImage,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 140,
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
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 140,
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
                    ),
                  // Overlay mờ để chữ nổi bật
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
                  // Badge (nếu có)
                  if (badge != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacityRatio(.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacityRatio(.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Phần thông tin workout
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên workout
                  Text(
                    title,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: .2,
                    ),
                  ),
                  // Subtitle (nếu có)
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  // Description (nếu có)
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description!,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Tags (nếu có)
                  if (tags != null && tags!.isNotEmpty) ...[
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
