// Dùng ở: home_screen. Biểu đồ thời gian tập luyện.
import 'package:flutter/material.dart';

// File không sử dụng
class WorkoutTimeChart extends StatelessWidget {
  const WorkoutTimeChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TabButton(label: 'Ngày', selected: true),
              const SizedBox(width: 8),
              TabButton(label: 'Tuần', selected: false),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                BarChartItem(
                  label: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][i],
                  value: [2, 3, 1, 3, 2, 2, 2][i],
                  highlight: i == 3,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  const TabButton({super.key, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF8854FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class BarChartItem extends StatelessWidget {
  final String label;
  final int value;
  final bool highlight;
  const BarChartItem({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 18,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 18,
              height: value * 15.0,
              decoration: BoxDecoration(
                color: highlight ? const Color(0xFFFF6B6B) : Colors.white38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: highlight
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Text(
                          '3 times',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
