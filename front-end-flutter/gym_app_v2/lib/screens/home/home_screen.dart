import 'package:flutter/services.dart';
import 'dart:math';
import '../../services/exercise_logs_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../repositories/current_user_repository.dart';
import '../../repositories/training_requests_repository.dart';
import '../coaches/coach_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../core/extensions/color_extensions.dart';
import '../../widgets/animations/animated_appear.dart';
import '../../widgets/skeleton/today_stat_skeleton.dart'; // CircleAvatarSkeleton
import '../../widgets/skeleton/skeleton_box.dart';
import '../coaches/coaches_screen.dart';
import '../appointments/appointments_screen.dart';
import '../coaches/coach_gymers_screen.dart';
// import '../workout/workout_screen.dart'; // No longer pushing directly

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

class HomeScreen extends StatefulWidget {
  final String userName;
  final bool isLoading;
  final String? userRole; // 'GYMER' | 'COACH'
  final VoidCallback? openWorkoutTab; // callback to jump to workout tab
  final VoidCallback? openWorkoutPlanTab; // open Plan tab of Workout
  const HomeScreen({
    super.key,
    required this.userName,
    this.isLoading = false,
    this.userRole,
    this.openWorkoutTab,
    this.openWorkoutPlanTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _Motivation {
  final String title;
  final String subtitle;
  const _Motivation(this.title, this.subtitle);
}

class _HomeScreenState extends State<HomeScreen> {
  late _Motivation _motivation;
  late int _motivationIndex;
  static const List<_Motivation> _motivations = [
    _Motivation(
      'Đẩy nhịp tim',
      'Mỗi rep hôm nay đặt nền móng sức mạnh ngày mai.',
    ),
    _Motivation(
      'Ổn định tạo bứt phá',
      'Nhỏ từng bước – tích luỹ thành tiến bộ lớn.',
    ),
    _Motivation('Vượt mệt mỏi', 'Bạn mạnh hơn cảm giác đuối hiện tại.'),
    _Motivation(
      'Kỷ luật quan trọng',
      'Động lực thoáng qua – kỷ luật mới lâu dài.',
    ),
    _Motivation('Tâm trí dẫn đường', 'Cơ thể thay đổi khi tư duy kiên định.'),
    _Motivation(
      'Tiến bộ > Hoàn hảo',
      'Không cần hoàn hảo, chỉ cần tốt hơn hôm qua.',
    ),
    _Motivation(
      'Đầu tư cho tương lai',
      'Bạn tập cho phiên bản mạnh mẽ hơn của chính mình.',
    ),
    _Motivation(
      'Một set nữa',
      'Chỉ 1 lần cố thêm cũng thay đổi đường cong tiến bộ.',
    ),
    _Motivation(
      'Nhịp độ ổn định',
      'Ổn định giúp bạn thắng người bùng nổ rồi bỏ cuộc.',
    ),
    _Motivation(
      'Tích luỹ nội lực',
      'Từng giọt mồ hôi là vốn liếng sức mạnh sau này.',
    ),
    _Motivation(
      'Tập trung hiện tại',
      'Khoảnh khắc này quyết định quỹ đạo của bạn.',
    ),
    _Motivation('Xây nền đúng', 'Nền tảng vững mang lại tăng trưởng bền lâu.'),
  ];

  Future<ExerciseStreak>? _streakFuture;
  bool _ptLoading = false;
  String? _resolvedRole; // added for dynamic role resolution
  String? _profilePictureUrl; // current user's profile picture
  UserModel? _fullUser; // cached full profile

  @override
  void initState() {
    super.initState();
    final r = Random();
    _motivationIndex = r.nextInt(_motivations.length);
    _motivation = _motivations[_motivationIndex];
    _resolveRoleIfNeeded();
    _loadFullProfile();
  }

  bool get isLoading => widget.isLoading;
  String get userName => widget.userName;
  String? get userRole => widget.userRole;

  Future<void> _resolveRoleIfNeeded() async {
    if (widget.userRole != null) {
      setState(() => _resolvedRole = widget.userRole);
      return;
    }
    final profile = await CurrentUserRepository().fetchProfile();
    if (!mounted) return;
    setState(() => _resolvedRole = profile?.role);
  }

  Future<void> _loadFullProfile() async {
    final user = await UserService.fetchProfile(context);
    if (!mounted) return;
    setState(() {
      _fullUser = user;
      _profilePictureUrl = user?.profilePicture;
    });
  }

  Future<void> _handlePtCardTap(BuildContext ctx) async {
    if (_ptLoading) return;
    setState(() => _ptLoading = true);
    try {
      final currentRepo = CurrentUserRepository();
      final trRepo = TrainingRequestsRepository();
      final profile = await currentRepo.fetchProfile();
      if (profile == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Không lấy được thông tin người dùng.')),
        );
        return;
      }
      if (profile.role == 'COACH') {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Tính năng học viên cho Coach sẽ sớm có.'),
          ),
        );
        return;
      }
      final entity = await currentRepo.fetchRoleEntity();
      if (entity is! GymerByUserResult) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Bạn không phải gymer.')));
        return;
      }
      final accepted = await trRepo.fetchAcceptedByGymer(gymerId: entity.id);
      if (accepted.isEmpty) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Bạn chưa có PT nào.')));
        return;
      }
      if (accepted.length == 1) {
        final coach = accepted.first['coach'] as Map?;
        final coachId = coach?['id'];
        if (coachId is String && coachId.isNotEmpty) {
          if (!mounted) return;
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => CoachDetailScreen(coachId: coachId),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      await showModalBottomSheet(
        context: ctx,
        backgroundColor: const Color(0xFF121214),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (bCtx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Chọn PT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...accepted.map((req) {
                    final coach = req['coach'] as Map?;
                    final user = coach != null ? coach['user'] as Map? : null;
                    final coachName = (user?['name'] ?? 'Coach') as String;
                    final coachId = coach?['id'] as String?;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF2A2A2E),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        coachName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                      onTap: coachId == null
                          ? null
                          : () {
                              Navigator.pop(bCtx);
                              Navigator.of(ctx).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CoachDetailScreen(coachId: coachId),
                                ),
                              );
                            },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _ptLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _streakFuture ??= _loadStreak();
  }

  Future<ExerciseStreak> _loadStreak() async {
    final res = await ExerciseLogsService.instance.getMyStreaks();
    if (res.data != null) return res.data!;
    final code = res.status;
    final msg = res.message ?? 'Không thể tải streak';
    throw '($code) $msg';
  }

  Widget _streakSection() {
    return FutureBuilder<ExerciseStreak>(
      future: _streakFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _streakSkeleton();
        }
        if (snapshot.hasError) {
          return _streakError(snapshot.error.toString());
        }
        final streak = snapshot.data;
        if (streak == null) {
          return _streakError('Không có dữ liệu');
        }
        return _streakCard(streak);
      },
    );
  }

  Widget _streakSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _streakDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBar(width: 120),
                const SizedBox(height: 12),
                _skeletonBar(width: 80),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _skeletonCircle(size: 54),
        ],
      ),
    );
  }

  Widget _skeletonBar({double width = 100, double height = 12}) => Container(
    width: width,
    height: height,
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.08),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  Widget _skeletonCircle({double size = 48}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.08),
      shape: BoxShape.circle,
    ),
  );

  BoxDecoration _streakDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      colors: [Color(0xFF121212), Color(0xFF1E1E21), Color(0xFF26262A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: Colors.white.withOpacity(.05), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.5),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  Widget _streakCard(ExerciseStreak streak) {
    final current = streak.currentStreak;
    final longest = streak.longestStreak;
    final lastDate = streak.lastWorkoutDate != null
        ? _formatDate(streak.lastWorkoutDate!)
        : '—';
    final accent = const Color(0xFFF5A623);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
      decoration: _streakDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuỗi ngày tập',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.92),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metricBlock(
                      label: 'Hiện tại',
                      value: '$current',
                      highlight: true,
                      accent: accent,
                    ),
                    const SizedBox(width: 22),
                    _metricBlock(
                      label: 'Kỷ lục',
                      value: '$longest',
                      accent: accent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(.55),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Buổi gần nhất: $lastDate',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.60),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          _streakFlame(current: current, accent: accent),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _metricBlock({
    required String label,
    required String value,
    bool highlight = false,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(.55),
            fontSize: 11.5,
            letterSpacing: .2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: highlight
                ? accent.withOpacity(.15)
                : Colors.white.withOpacity(.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight
                  ? accent.withOpacity(.55)
                  : Colors.white.withOpacity(.08),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? accent : Colors.white.withOpacity(.85),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _streakFlame({required int current, required Color accent}) {
    final base = current.clamp(0, 30);
    final size = 48 + (base * 0.6); // scale a bit with streak length
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [accent.withOpacity(.65), accent.withOpacity(.15)],
          radius: .9,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: size * 0.55,
            color: accent,
          ),
          Positioned(
            bottom: 6,
            child: Text(
              '$current',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.26,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(.5), blurRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _streakDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Không tải được dữ liệu',
            style: TextStyle(
              color: Colors.white.withOpacity(.85),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(.55),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              setState(() {
                _streakFuture = _loadStreak();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(.08),
                border: Border.all(color: Colors.white.withOpacity(.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Thử lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                _streakSection(),
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
            _buildProfileAvatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? 'Chào bạn'
                      : 'Chào, ${(_fullUser != null && _fullUser!.name.isNotEmpty) ? _fullUser!.name : userName}',
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

  Widget _buildProfileAvatar() {
    final url = _profilePictureUrl;
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => _fallbackAvatar(),
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.white.withOpacity(.05),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              (progress.expectedTotalBytes ?? 1)
                        : null,
                    color: Colors.orange.shade400,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
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
    final role = _resolvedRole ?? userRole;
    final dynamicLabel = role == 'COACH' ? 'Học viên của tôi' : 'PT của tôi';
    final dynamicSubtitle = role == 'COACH'
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
            label: 'Cuộc hẹn',
            subtitle: 'Lịch hẹn & theo dõi',
            icon: Icons.event_available,
            gradient: const [
              Color(0xFF3A1C71),
              Color(0xFFD76D77),
              Color(0xFFFFAF7B),
            ],
            onTap: () {
              Navigator.of(outerCtx).push(
                MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
              );
            },
          ),
          _DiscoverItem(
            label: 'Tìm lộ trình',
            subtitle: 'Kế hoạch & mục tiêu',
            icon: Icons.route_rounded,
            gradient: const [Color(0xFF283048), Color(0xFF859398)],
            onTap: () {
              widget.openWorkoutTab?.call();
            },
          ),
          _DiscoverItem(
            label: dynamicLabel,
            subtitle: dynamicSubtitle,
            icon: userRole == 'COACH' ? Icons.group : Icons.person_pin_circle,
            gradient: const [Color(0xFF141E30), Color(0xFF243B55)],
            onTap: () => role == 'COACH'
                ? Navigator.of(outerCtx).push(
                    MaterialPageRoute(
                      builder: (_) => const CoachGymersScreen(),
                    ),
                  )
                : _handlePtCardTap(outerCtx),
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
              children: items.map((i) {
                final widgetTile = _exploreSquare(i, tileWidth, tileHeight);
                if (i.label == dynamicLabel) {
                  return Stack(
                    children: [
                      widgetTile,
                      if (_ptLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.black.withOpacity(.35),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
                return widgetTile;
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _exploreSquare(_DiscoverItem item, double w, double h) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: item.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.50),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, size: 26, color: Colors.white.withOpacity(.92)),
              const SizedBox(height: 10),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.70),
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
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
    // Themed gradient palette (dark base + subtle accent). Index mapped by _motivationIndex mod length
    const gradients = [
      [Color(0xFF1F1F20), Color(0xFF323245), Color(0xFF454560)],
      [Color(0xFF1C1D22), Color(0xFF2B3A4A), Color(0xFF244E6B)],
      [Color(0xFF211E24), Color(0xFF3A2742), Color(0xFF53345E)],
      [Color(0xFF1E2022), Color(0xFF2F3F3C), Color(0xFF426255)],
      [Color(0xFF1E1F23), Color(0xFF333648), Color(0xFF4A5072)],
      [Color(0xFF201F24), Color(0xFF3B2F2F), Color(0xFF5A3E30)],
    ];
    final colors = gradients[_motivationIndex % gradients.length];
    final accent = colors.last;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(.32),
            blurRadius: 26,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _motivation.title,
            style: TextStyle(
              color: Colors.white.withOpacity(.96),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _motivation.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(.85),
              fontSize: 13.5,
              height: 1.32,
              fontWeight: FontWeight.w500,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: widget.openWorkoutPlanTab,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                // Darker, richer pill using accent tint gradient
                gradient: LinearGradient(
                  colors: [accent.withOpacity(.33), accent.withOpacity(.22)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(.40),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
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
          ),
        ],
      ),
    );
  }
}
