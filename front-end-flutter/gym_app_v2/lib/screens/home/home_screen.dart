import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
import '../../widgets/discover_button.dart';
import '../../widgets/today_stat.dart';
import '../../widgets/animations/animated_appear.dart';
import '../../widgets/skeleton/today_stat_skeleton.dart';
import '../../widgets/skeleton/skeleton_box.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final bool isLoading;
  const HomeScreen({super.key, required this.userName, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AnimatedAppear(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        if (isLoading)
                          const CircleAvatarSkeleton(size: 44)
                        else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade400,
                                  Colors.orange.shade600,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacityRatio(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isLoading)
                                const SkeletonBox(
                                  width: 80,
                                  height: 10,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(4),
                                  ),
                                )
                              else
                                const Text(
                                  'Chào bạn,',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: isLoading
                                    ? const SkeletonBox(
                                        key: ValueKey('name_skel'),
                                        width: 120,
                                        height: 14,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(4),
                                        ),
                                      )
                                    : Text(
                                        userName,
                                        key: const ValueKey('name'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        _iconCircle(isLoading, Icons.chat_bubble_outline),
                        const SizedBox(width: 8),
                        _iconCircle(isLoading, Icons.notifications_none),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedAppear(
                  delay: const Duration(milliseconds: 80),
                  child: const Text(
                    'Khám phá',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedAppear(
                  delay: const Duration(milliseconds: 140),
                  child: isLoading
                      ? Row(
                          children: const [
                            SkeletonBox(width: 90, height: 40),
                            SizedBox(width: 12),
                            SkeletonBox(width: 120, height: 40),
                            SizedBox(width: 12),
                            SkeletonBox(width: 100, height: 40),
                          ],
                        )
                      : Row(
                          children: [
                            DiscoverButton(label: 'Coaches'),
                            const SizedBox(width: 12),
                            DiscoverButton(label: 'Achievements'),
                            const SizedBox(width: 12),
                            DiscoverButton(label: 'My coach'),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                AnimatedAppear(
                  delay: const Duration(milliseconds: 200),
                  child: const Text(
                    'Thống kê hôm nay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedAppear(
                  delay: const Duration(milliseconds: 260),
                  child: isLoading
                      ? const TodayStatSkeleton()
                      : const TodayStat(
                          workoutSets: 6, // TODO: bind real data
                          exercisesCount: 24, // placeholder exercises count
                          calories: 660,
                          points: 300,
                          compact: false,
                        ),
                ),
                const SizedBox(height: 8),
                // (Đã bỏ phần biểu đồ thời gian tập luyện theo yêu cầu)
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconCircle(bool loading, IconData icon) {
    if (loading) {
      return const SkeletonBox(
        width: 40,
        height: 40,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[700]!, width: 0.5),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 20),
        onPressed: () {},
        padding: EdgeInsets.zero,
      ),
    );
  }
}
