import 'package:flutter/material.dart';
import 'log_tab.dart';

class LogWorkoutTimeCard extends StatelessWidget {
  const LogWorkoutTimeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: const [
          //     LogTab(label: 'Ngày', selected: true),
          //     SizedBox(width: 8),
          //     LogTab(label: 'Tuần'),
          //   ],
          // ),
          // const SizedBox(height: 12),
          const Text(
            '4 Jan - 10 Jan', 
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BarChartItem(label: 'Sun', value: 2, highlight: false),
              BarChartItem(label: 'Mon', value: 3, highlight: false),
              BarChartItem(label: 'Tue', value: 5, highlight: true),
              BarChartItem(label: 'Wed', value: 3, highlight: false),
              BarChartItem(label: 'Thu', value: 2, highlight: false),
              BarChartItem(label: 'Fri', value: 2, highlight: false),
              BarChartItem(label: 'Sat', value: 2, highlight: false),
            ],
          ),
        ],
      ),
    );
  }
}

class BarChartItem extends StatelessWidget {
  final String label;
  final int value;
  final bool highlight;
  const BarChartItem({
    Key? key,
    required this.label,
    required this.value,
    this.highlight = false,
  }) : super(key: key);

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
              height: value * 12.0,
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
