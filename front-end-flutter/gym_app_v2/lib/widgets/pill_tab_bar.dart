import 'package:flutter/material.dart';

/// A reusable pill-style TabBar wrapper with consistent horizontal padding
/// and rounded indicator. Supply either `tabs` or `labels`.
class PillTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Widget>? tabs; // custom tab children
  final List<String>? labels; // convenience: creates Text tabs
  final EdgeInsetsGeometry horizontalPadding;
  final double height;
  final bool isScrollable;
  final Color indicatorColor;
  final double indicatorOpacity;
  final double borderRadius;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color labelColor;
  final Color unselectedLabelColor;

  PillTabBar({
    super.key,
    required this.controller,
    this.tabs,
    this.labels,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = kTextTabBarHeight + 12,
    this.isScrollable = false,
    this.indicatorColor = const Color(0xFF8854FF),
    this.indicatorOpacity = 0.18,
    this.borderRadius = 14,
    this.labelStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    this.unselectedLabelStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    this.labelColor = Colors.white,
    this.unselectedLabelColor = Colors.white60,
  }) : assert(tabs != null || labels != null),
       assert(!(tabs != null && labels != null));

  List<Widget> _buildTabs() {
    if (tabs != null) return tabs!;
    return labels!
        .map(
          (text) => Tab(
            child: Center(
              child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: Padding(
        padding: horizontalPadding,
        child: TabBar(
          controller: controller,
          isScrollable: isScrollable,
          labelColor: labelColor,
          unselectedLabelColor: unselectedLabelColor,
          labelStyle: labelStyle,
          unselectedLabelStyle: unselectedLabelStyle,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: indicatorColor.withOpacity(indicatorOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 6,
          ),
          labelPadding: EdgeInsets.zero,
          tabs: _buildTabs(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
