import 'package:flutter/material.dart';

class WorkoutTabBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  const WorkoutTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy width màn hình, trừ padding 20*2 giống box search
    final double barWidth = MediaQuery.of(context).size.width - 40;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
        width: barWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => onTabSelected(0),
              child: _Tab(label: 'Khám phá', selected: selectedTab == 0),
            ),
            GestureDetector(
              onTap: () => onTabSelected(1),
              child: _Tab(label: 'Kế hoạch', selected: selectedTab == 1),
            ),
            GestureDetector(
              onTap: () => onTabSelected(2),
              child: _Tab(label: 'Chuyên gia', selected: selectedTab == 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  const _Tab({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: 100,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF8854FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
