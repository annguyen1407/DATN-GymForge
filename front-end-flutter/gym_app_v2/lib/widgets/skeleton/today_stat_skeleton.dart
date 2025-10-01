import 'package:flutter/material.dart';
import 'skeleton_box.dart';

class TodayStatSkeleton extends StatelessWidget {
  final bool compact;
  const TodayStatSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (_) => SkeletonBox(
            width: 74,
            height: 74,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SkeletonBox(
          width: 86,
          height: 100,
          borderRadius: BorderRadius.circular(20),
        ),
        SkeletonBox(
          width: 86,
          height: 100,
          borderRadius: BorderRadius.circular(20),
        ),
        SkeletonBox(
          width: 86,
          height: 100,
          borderRadius: BorderRadius.circular(20),
        ),
        SkeletonBox(
          width: 86,
          height: 100,
          borderRadius: BorderRadius.circular(20),
        ),
      ],
    );
  }
}

class CircleAvatarSkeleton extends StatelessWidget {
  final double size;
  const CircleAvatarSkeleton({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
      ),
    );
  }
}
