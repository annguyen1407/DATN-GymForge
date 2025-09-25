import 'package:flutter/material.dart';
import 'dart:ui';

/// A compact, scrollable numeric pagination bar.
/// - Shows first & last page shortcuts when far.
/// - Ellipsis markers when there is a gap.
/// - Current page highlighted.
class PaginationBar extends StatelessWidget {
  final int currentPage; // 1-based
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final EdgeInsets padding;

  /// How many page numbers to show inside one group window (excluding first/last shortcuts)
  final int groupSize;

  /// Whether to always show first & last page when they're outside the current group.
  final bool showEdgePages;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.groupSize = 7,
    this.showEdgePages = true,
  });

  int get totalPages => (totalItems / pageSize).ceil().clamp(1, 999999);

  /// Compact pattern: Always show 1,2 and last-1,last. Include current page if it's
  /// not already in those sets. Use ellipsis for any gaps >1.
  /// If total pages <=6 just show all pages.
  List<int?> _buildPageList(int effectiveGroupSize) {
    final tp = totalPages;
    if (tp <= 6) {
      return [for (int i = 1; i <= tp; i++) i];
    }

    final pages = <int?>[];
    final core = <int>{1, 2, tp - 1, tp};
    if (currentPage > 2 && currentPage < tp - 1) core.add(currentPage);
    final ordered = core.toList()..sort();
    int? last;
    for (final p in ordered) {
      if (last != null && p - last > 1) pages.add(null);
      pages.add(p);
      last = p;
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final tp = totalPages;
    if (tp <= 1) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    // Adaptive group size to avoid overflow on narrow devices.
    int effectiveGroupSize = groupSize;
    if (width < 340) {
      effectiveGroupSize = effectiveGroupSize.clamp(3, 4);
    } else if (width < 370) {
      effectiveGroupSize = effectiveGroupSize.clamp(3, 5);
    } else if (width < 410) {
      effectiveGroupSize = effectiveGroupSize.clamp(3, 6);
    }

    final pages = _buildPageList(effectiveGroupSize);
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x2214181B), Color(0x3314181B)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141517).withOpacity(0.60),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Estimate width consumption; if still risk overflow, fall back to scroll with Flexible.
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _navBtn(
                            icon: Icons.chevron_left,
                            enabled: currentPage > 1,
                            onTap: () => onPageChanged(currentPage - 1),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  for (final p in pages) ...[
                                    if (p == null)
                                      _ellipsis()
                                    else
                                      _pageBtn(
                                        p,
                                        compact: constraints.maxWidth < 360,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          _navBtn(
                            icon: Icons.chevron_right,
                            enabled: currentPage < tp,
                            onTap: () => onPageChanged(currentPage + 1),
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
      ),
    );
  }

  Widget _pageBtn(int page, {bool compact = false}) {
    final selected = page == currentPage;
    final baseHeight = 38.0;
    final minWidth = compact ? 34.0 : 42.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: selected ? null : () => onPageChanged(page),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: baseHeight,
          constraints: BoxConstraints(minWidth: minWidth),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? (compact ? 12 : 16) : (compact ? 8 : 12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFFF855E), Color(0xFFFF5B6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : const Color(0xFF232528),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: Colors.white.withOpacity(selected ? 0.97 : 0.72),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: selected
                    ? (compact ? 13.5 : 14.5)
                    : (compact ? 11.5 : 12.5),
                letterSpacing: 0.15,
              ),
              child: Text('$page'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ellipsis() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: const Color(0xFF232528),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Text(
        '…',
        style: TextStyle(
          color: Colors.white.withOpacity(0.50),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _navBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.28,
          child: Container(
            height: 38,
            width: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF232528),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: Colors.white.withOpacity(0.80)),
          ),
        ),
      ),
    );
  }
}
