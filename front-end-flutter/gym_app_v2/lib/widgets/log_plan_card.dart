import 'package:flutter/material.dart';

/// Public reusable PlanCard widget extracted from log_day_screen.dart
/// Accepts a plan Map (expects keys: name, progress (0..1), dayNumber, exercises (List))
/// External builders supply planTypeColor, dayBadge, planTypeChip for flexible styling.
class PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onTap;
  final Color planTypeColor;
  final Widget
  dayBadge; // deprecated visual (kept for backward compatibility – not rendered)
  final Widget planTypeChip;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    required this.planTypeColor,
    required this.dayBadge,
    required this.planTypeChip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (plan['progress'] as double).clamp(0.0, 1.0);
    final exercisesCount = (plan['exercises'] as List).length;
    // Derive localized plan type label from raw chip (if it's a Text or provides semantic). We also allow upstream override by passing a custom planTypeChip.
    Widget effectivePlanTypeChip = planTypeChip;
    // If caller passed a SizedBox or empty, keep as is.
    // Attempt to extract raw type from plan map if we want to override label.
    final rawType = (plan['planType'] ?? plan['type'] ?? plan['plan_type'])
        ?.toString();
    if (rawType != null && rawType.trim().isNotEmpty) {
      final t = rawType.toUpperCase();
      final localized = _localizedPlanType(t);
      // Build a new chip with higher contrast if we can localize.
      if (localized != null) {
        final color = planTypeColor;
        effectivePlanTypeChip = _SmallChip(
          label: localized,
          icon: Icons.label_important,
          color: color.withOpacity(.95),
        );
      }
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190, // enlarged height for better breathing space
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[850]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.55),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gradient background top area (expanded subtle)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      planTypeColor.withOpacity(.60),
                      Colors.black.withOpacity(.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Content column with bottom anchored progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & top meta row (simplified – removed day label/badge)
                  Text(
                    plan['name']?.toString() ?? 'Kế hoạch',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      letterSpacing: .25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (effectivePlanTypeChip is SizedBox == false)
                        effectivePlanTypeChip,
                      if (plan['dayNumber'] != null)
                        _SmallChip(
                          label: 'Ngày thứ ${plan['dayNumber']}',
                          icon: Icons.today,
                          color: planTypeColor.withOpacity(.90),
                        ),
                      _SmallChip(
                        label: '$exercisesCount bài tập',
                        icon: Icons.fitness_center,
                        color: planTypeColor.withOpacity(.85),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Progress bar anchored at bottom
                  // Progress bar (clean – no outer border container now)
                  SizedBox(
                    height: 24,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            decoration: BoxDecoration(color: Colors.grey[850]),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 620),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    planTypeColor.withOpacity(.95),
                                    const Color(0xFF8854FF),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          // subtle moving sheen effect
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                opacity: 0.22,
                                duration: const Duration(milliseconds: 1600),
                                curve: Curves.easeInOut,
                                child: ShaderMask(
                                  shaderCallback: (rect) {
                                    return LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(.55),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ).createShader(rect);
                                  },
                                  blendMode: BlendMode.srcATop,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white12,
                                          Colors.white10,
                                          Colors.white12,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Soft interactive overlay highlight on tap-down (basic feedback can be extended with GestureDetector states)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(.025),
                        Colors.white.withOpacity(.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to localize plan type (returns null if unknown to avoid overriding custom chips)
String? _localizedPlanType(String upperType) {
  switch (upperType) {
    case 'COMBINED':
    case 'TOTAL': // optional alias if backend uses different label
      return 'Kết hợp';
    case 'STRENGTH':
      return 'Sức mạnh';
    case 'CARDIO':
    case 'ENDURANCE':
      return 'Sức bền';
    case 'FLEXIBILITY':
    case 'MOBILITY':
      return 'Dẻo dai';
    default:
      return null; // keep original
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SmallChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Improve contrast: darker translucent background + subtle inner highlight via gradient
    final bg = Color.lerp(Colors.black, color, 0.25)!;
    final textColor = Colors.white; // enforce white text for readability
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.55), width: 1),
        gradient: LinearGradient(
          colors: [bg.withOpacity(.70), bg.withOpacity(.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor.withOpacity(.92)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
