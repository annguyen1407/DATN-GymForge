// Dùng ở: main_screen. Thanh điều hướng dưới cùng của app.
import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  // Optional: allow injection later (kept minimal now)
  final List<IconData> icons = const [
    Icons.home,
    Icons.article_rounded,
    Icons.fitness_center,
    Icons.bar_chart_rounded,
    Icons.person,
  ];

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 60;
    const double highlightWidth = 54;
    const double highlightHeight = 40;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.black.withValues(alpha: 0.58),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04),
                  width: 0.7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                height: barHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final itemWidth = width / icons.length;
                    final left =
                        currentIndex * itemWidth +
                        (itemWidth - highlightWidth) / 2;
                    return Stack(
                      children: [
                        // selection highlight (smaller capsule behind icon)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          left: left,
                          top: (barHeight - highlightHeight) / 2,
                          width: highlightWidth,
                          height: highlightHeight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFF8854FF,
                                  ).withValues(alpha: 0.32),
                                  const Color(
                                    0xFF8854FF,
                                  ).withValues(alpha: 0.07),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (int i = 0; i < icons.length; i++)
                              _NavItem(
                                icon: icons[i],
                                selected: currentIndex == i,
                                onTap: () => onTap(i),
                                showDot: i == 3,
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool showDot;
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                child: Icon(
                  icon,
                  size: 25,
                  color: selected
                      ? const Color(0xFFBFA2FF)
                      : Colors.white.withValues(alpha: 0.62),
                ),
              ),
              if (selected && showDot)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8854FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
