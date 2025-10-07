import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../repositories/current_user_repository.dart';
import '../../repositories/training_requests_repository.dart';
import '../../repositories/gymers_repository.dart';
import '../gymer/gymer_detail_screen.dart';

/// Screen: List of gymers (accepted training requests) for the logged-in coach
class CoachGymersScreen extends StatefulWidget {
  const CoachGymersScreen({super.key});

  @override
  State<CoachGymersScreen> createState() => _CoachGymersScreenState();
}

class _CoachGymersScreenState extends State<CoachGymersScreen> {
  bool _loading = true;
  String? _error;
  List<_RawGymerRef> _gymerRefs = [];
  final _gymerRepo = GymersRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final currentRepo = CurrentUserRepository();
      final profile = await currentRepo.fetchProfile();
      if (profile?.role != 'COACH') {
        setState(() {
          _error = 'Bạn không phải coach';
          _loading = false;
        });
        return;
      }
      final coachEntity = await currentRepo.fetchRoleEntity();
      if (coachEntity is! CoachByUserResult) {
        setState(() {
          _error = 'Không lấy được thông tin coach';
          _loading = false;
        });
        return;
      }
      final trRepo = TrainingRequestsRepository();
      final list = await trRepo.fetchAcceptedByCoach(coachId: coachEntity.id);
      final refs = <_RawGymerRef>[];
      for (final m in list) {
        try {
          final gymer = m['gymer'] as Map?;
          final user = gymer != null ? gymer['user'] as Map? : null;
          if (gymer == null || user == null) continue;
          final gymerId = gymer['id'] as String? ?? '';
          final userId = user['id'] as String? ?? '';
          if (gymerId.isEmpty || userId.isEmpty) continue;
          refs.add(_RawGymerRef(gymerId: gymerId, userId: userId));
        } catch (_) {}
      }
      setState(() {
        _gymerRefs = refs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        backgroundColor: DesignTokens.bg,
        elevation: 0,
        title: const Text('Học viên của tôi'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Làm mới',
            icon: Icon(
              Icons.refresh_rounded,
              color: _loading ? Colors.white24 : Colors.white,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      // Full-screen skeleton list placeholder (3 items)
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: 3,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _SkeletonCard(index: i),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_gymerRefs.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có học viên nào được chấp nhận.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return RefreshIndicator(
      color: DesignTokens.brand,
      backgroundColor: DesignTokens.bg,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _gymerRefs.length,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemBuilder: (_, i) {
          final ref = _gymerRefs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _GymerCard(
              userId: ref.userId,
              gymerId: ref.gymerId,
              repo: _gymerRepo,
            ),
          );
        },
      ),
    );
  }
}

class _RawGymerRef {
  final String gymerId;
  final String userId;
  _RawGymerRef({required this.gymerId, required this.userId});
}

class _GymerCard extends StatefulWidget {
  final String userId;
  final String gymerId;
  final GymersRepository repo;
  const _GymerCard({
    required this.userId,
    required this.gymerId,
    required this.repo,
  });

  @override
  State<_GymerCard> createState() => _GymerCardState();
}

class _GymerCardState extends State<_GymerCard> {
  GymerDetailModel? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await widget.repo.fetchByUserId(widget.userId);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Persist the outer decoration so we don't briefly show a black background (missing border)
    // during the first frame when switching from skeleton -> content. The AnimatedSwitcher now
    // only animates the inner payload; the gradient/border container stays mounted.
    return Container(
      decoration: _cardDecoration(),
      child: AnimatedSwitcher(
        duration: DesignTokens.durationNormal,
        child: _loading
            ? _skeletonBody(key: const ValueKey('skeleton'))
            : _contentBody(),
      ),
    );
  }

  Widget _contentBody() {
    final user = _detail?.user;
    final name = (user?['name'] as String?) ?? 'Gymer';
    final avatar = _detail?.pictureProfile ?? user?['profilePicture'];
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              GymerDetailScreen(userId: widget.userId, gymerId: widget.gymerId),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      splashColor: Colors.white.withOpacity(.06),
      highlightColor: Colors.white.withOpacity(.04),
      child: Ink(
        // Decoration moved to persistent parent container.
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _avatar(avatar, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(.92),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(.55),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => const BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    gradient: LinearGradient(
      colors: [Color(0xFF1B1B1D), Color(0xFF26262A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x0FFFFFFF), width: 1),
    ),
  );

  Widget _skeletonBody({Key? key}) => Container(
    key: key,
    // Decoration handled by persistent parent.
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        _avatar(null, size: 56, dim: true),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skBar(width: 120, height: 16, opacity: .16),
              const SizedBox(height: 8),
              _skBar(width: 160, height: 10, opacity: .08),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _skBar({
    double width = 100,
    double height = 12,
    double opacity = .15,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  Widget _avatar(String? url, {bool dim = false, double size = 56}) {
    if (url != null && url.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(dim: dim, size: size),
          loadingBuilder: (c, child, progress) =>
              progress == null ? child : _fallback(dim: true, size: size),
        ),
      );
    }
    return _fallback(dim: dim, size: size);
  }

  Widget _fallback({bool dim = false, double size = 56}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: dim
            ? [Colors.white.withOpacity(.08), Colors.white.withOpacity(.04)]
            : [const Color(0xFF383838), const Color(0xFF2A2A2E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: Colors.white.withOpacity(.08)),
    ),
    child: Icon(
      Icons.person,
      color: Colors.white.withOpacity(dim ? .25 : .85),
      size: size * 0.48,
    ),
  );
}

/// Standalone skeleton card for initial full-screen list load.
class _SkeletonCard extends StatelessWidget {
  final int index;
  const _SkeletonCard({required this.index});

  @override
  Widget build(BuildContext context) {
    // TODO(UX): Consider adding a subtle shimmer animation using an AnimationController
    // or a reusable Shimmer widget once performance profiling confirms it's cheap.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1B1D), Color(0xFF232327)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatarSkeleton(),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(width: 120, height: 16),
                const SizedBox(height: 8),
                _block(width: 160, height: 10, opacity: .08),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarSkeleton() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(.07),
    ),
  );

  Widget _block({
    required double width,
    required double height,
    double opacity = .15,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(8),
    ),
  );
  // Removed chipBlock placeholders to stay consistent with simplified gymer card (only avatar + name)
}
