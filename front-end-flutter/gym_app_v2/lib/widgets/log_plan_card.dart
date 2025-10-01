import 'package:flutter/material.dart';

/// Public reusable PlanCard widget extracted from log_day_screen.dart
/// Accepts a plan Map (expects keys: name, progress (0..1), dayNumber, exercises (List))
/// External builders supply planTypeColor, dayBadge, planTypeChip for flexible styling.
class PlanCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onTap;
  final Color planTypeColor;
  final Widget dayBadge; // kept for backward compatibility (not rendered)
  final Widget planTypeChip; // Expected to be a PlanTypeBadge (dense)
  final int? appearIndex; // optional stagger index
  final bool showExerciseCount; // toggle hiển thị số bài tập

  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    required this.planTypeColor,
    required this.dayBadge,
    required this.planTypeChip,
    this.appearIndex,
    this.showExerciseCount = true,
  });

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: .0, end: 1.0).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, .06),
      end: Offset.zero,
    ).animate(curve);
    // Stagger start (optional)
    final delayMs = (widget.appearIndex ?? 0) * 60;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) => setState(() => _pressed = true);
  void _onTapCancel() => setState(() => _pressed = false);
  void _onTap() {
    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    // progress no longer displayed (handled in detail screen)
    final exercisesCount = (plan['exercises'] as List?)?.length ?? 0;
    final dayNumber = plan['dayNumber'];
    final color = widget.planTypeColor;
    // Use the provided planTypeChip directly (no override) to preserve unified label & style.
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: _onTap,
          onTapDown: _onTapDown,
          onTapCancel: _onTapCancel,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            scale: _pressed ? .965 : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[850]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .55),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (gradient like WorkoutCard image placeholder)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: .55),
                                  Colors.black.withValues(alpha: .85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // overlay gradient for readability
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: .05),
                                    Colors.black.withValues(alpha: .55),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          if (widget.planTypeChip is SizedBox == false)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: widget.planTypeChip,
                            ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 12,
                            child: Text(
                              plan['name']?.toString() ?? 'Kế hoạch',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (dayNumber != null)
                              _SmallChip(
                                label: 'Ngày ${dayNumber.toString()}',
                                icon: Icons.today,
                                color: color.withValues(alpha: .90),
                              ),
                            if (widget.showExerciseCount)
                              _SmallChip(
                                label: '$exercisesCount bài tập',
                                icon: Icons.fitness_center,
                                color: color.withValues(alpha: .85),
                              ),
                            // Removed progress percentage chip
                          ],
                        ),
                        // Removed progress bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        border: Border.all(color: color.withValues(alpha: .55), width: 1),
        gradient: LinearGradient(
          colors: [bg.withValues(alpha: .70), bg.withValues(alpha: .55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .18),
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
            Icon(icon, size: 13, color: textColor.withValues(alpha: .92)),
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
