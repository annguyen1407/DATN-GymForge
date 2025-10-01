import 'package:flutter/material.dart';

/// SegmentedPillSwitch: two or more segments behaving like a toggle, styled similar to PillTabBar
class SegmentedPillSwitch extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;
  final TextStyle? activeTextStyle;
  final TextStyle? inactiveTextStyle;
  final Duration animationDuration;

  const SegmentedPillSwitch({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 36,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(4),
    this.backgroundColor = const Color(0xFF2A2A2E),
    this.activeColor = const Color(0xFF8854FF),
    this.inactiveColor = Colors.transparent,
    this.activeTextStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
    this.inactiveTextStyle = const TextStyle(
      color: Color.fromARGB(111, 255, 255, 255),
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
    this.animationDuration = const Duration(milliseconds: 220),
  });

  @override
  Widget build(BuildContext context) {
    assert(labels.isNotEmpty, 'labels cannot be empty');
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth =
              (constraints.maxWidth - (padding.horizontal)) / labels.length;
          return Stack(
            children: [
              // Active pill background
              AnimatedPositioned(
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                left: selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: AnimatedContainer(
                  duration: animationDuration,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(borderRadius - 4),
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < labels.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: selectedIndex == i,
                        label: labels[i],
                        child: InkWell(
                          borderRadius: BorderRadius.circular(borderRadius - 4),
                          onTap: () => onChanged(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: animationDuration,
                              style: selectedIndex == i
                                  ? activeTextStyle!
                                  : inactiveTextStyle!,
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
