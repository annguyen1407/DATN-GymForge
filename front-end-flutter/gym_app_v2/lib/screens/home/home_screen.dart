import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
import '../../widgets/animations/animated_appear.dart';
import '../../widgets/skeleton/today_stat_skeleton.dart'; // CircleAvatarSkeleton
import '../../widgets/skeleton/skeleton_box.dart';
import '../coaches/coaches_screen.dart';
import '../achievements/achievements_screen.dart';

/// Data model for each discover square.
class _DiscoverItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _DiscoverItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class HomeScreen extends StatelessWidget {
  final String userName;
  final bool isLoading;
  final String? userRole; // 'GYMER' | 'COACH'
  final VoidCallback? openWorkoutTab; // callback to jump to workout tab
  const HomeScreen({
    super.key,
    required this.userName,
    this.isLoading = false,
    this.userRole,
    this.openWorkoutTab,
  });

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
                _header(),
                const SizedBox(height: 28),
                _exploreGrid(isLoading),
                const SizedBox(height: 40),
                _motivationCard(isLoading),
                const SizedBox(height: 40),
                const Text(
                  'Tiến độ hôm nay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 12),
                // Placeholder for future progress section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF101010), Color(0xFF1A1A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white24.withOpacity(.06),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isLoading
                        ? 'Đang tải...'
                        : 'Nội dung tiến độ sẽ xuất hiện ở đây',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.55),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return AnimatedAppear(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isLoading)
            const CircleAvatarSkeleton(size: 48)
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacityRatio(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? 'Chào bạn' : 'Chào, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sẵn sàng cho buổi tập tuyệt vời hôm nay?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isLoading) ...[
            const SkeletonBox(
              width: 36,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            const SizedBox(width: 10),
            const SkeletonBox(
              width: 36,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ] else ...[
            _iconCircle(Icons.notifications_none_rounded),
            const SizedBox(width: 10),
            _iconCircle(Icons.search_rounded),
          ],
        ],
      ),
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(.06),
        border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white.withOpacity(.85), size: 20),
    );
  }

  /// Explore 2x2 grid section
  Widget _exploreGrid(bool loading) {
    final dynamicLabel = userRole == 'COACH' ? 'Học viên' : 'PT của tôi';
    final dynamicSubtitle = userRole == 'COACH'
        ? 'Danh sách học viên'
        : 'Theo sát cùng bạn';
    return LayoutBuilder(
      builder: (outerCtx, constraints) {
        final items = <_DiscoverItem>[
          _DiscoverItem(
            label: 'Tìm kiếm PT',
            subtitle: 'Chuyên gia hướng dẫn',
            icon: Icons.search_rounded,
            gradient: const [Color(0xFF232526), Color(0xFF414345)],
            onTap: () {
              Navigator.of(
                outerCtx,
              ).push(MaterialPageRoute(builder: (_) => const CoachesScreen()));
            },
          ),
          _DiscoverItem(
            label: 'Thành tựu',
            subtitle: 'Badges & cột mốc',
            icon: Icons.emoji_events,
            gradient: const [
              Color(0xFF3A1C71),
              Color(0xFFD76D77),
              Color(0xFFFFAF7B),
            ],
            onTap: () {
              Navigator.of(outerCtx).push(
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
          ),
          _DiscoverItem(
            label: 'Lộ trình',
            subtitle: 'Kế hoạch & mục tiêu',
            icon: Icons.route_rounded,
            gradient: const [Color(0xFF283048), Color(0xFF859398)],
            onTap: () {
              if (openWorkoutTab != null) openWorkoutTab!();
            },
          ),
          _DiscoverItem(
            label: dynamicLabel,
            subtitle: dynamicSubtitle,
            icon: userRole == 'COACH' ? Icons.group : Icons.person_pin_circle,
            gradient: const [Color(0xFF141E30), Color(0xFF243B55)],
            onTap: () {},
          ),
        ];
        final width = constraints.maxWidth;
        const spacing = 16.0; // more compact spacing
        final tileWidth = (width - spacing) / 2; // two columns
        const tileHeight = 115.0; // reduced height for compact tiles
        if (loading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Khám phá',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(
                  4,
                  (_) => Container(
                    width: tileWidth,
                    height: tileHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: Colors.white.withOpacity(.05),
                    ),
                    child: const SkeletonBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.all(Radius.circular(26)),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khám phá',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items
                  .map((i) => _exploreSquare(i, tileWidth, tileHeight))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _exploreSquare(_DiscoverItem item, double w, double h) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            colors: item.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.55),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, size: 32, color: Colors.white.withOpacity(.92)),
              const Spacer(),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(.70),
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  letterSpacing: .2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _motivationCard(bool loading) {
    if (loading) {
      return const SkeletonBox(
        width: double.infinity,
        height: 170,
        borderRadius: BorderRadius.all(Radius.circular(34)),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange.shade400,
            Colors.orange.shade600,
            Colors.orange.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đẩy giới hạn của bạn',
            style: TextStyle(
              color: Colors.white.withOpacity(.95),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mỗi buổi tập là một bước tiến gần hơn tới phiên bản mạnh mẽ nhất của chính bạn.',
            style: TextStyle(
              color: Colors.white.withOpacity(.85),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withOpacity(.20),
              border: Border.all(
                color: Colors.white.withOpacity(.20),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Bắt đầu ngay',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
