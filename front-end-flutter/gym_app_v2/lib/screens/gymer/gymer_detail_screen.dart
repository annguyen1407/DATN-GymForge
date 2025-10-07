import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/gymers_repository.dart';
import '../../repositories/workout_plans_repository.dart';
import '../../repositories/training_requests_repository.dart';
import '../../repositories/current_user_repository.dart';
import '../../widgets/workout_card.dart';
import '../../models/workout_plan_model.dart';
import '../workout/create_workout_plan_screen.dart';
import '../workout/workout_detail_screen.dart';

class GymerDetailScreen extends StatefulWidget {
  final String userId; // gymer user id
  final String gymerId; // gymer role id
  const GymerDetailScreen({
    super.key,
    required this.userId,
    required this.gymerId,
  });

  @override
  State<GymerDetailScreen> createState() => _GymerDetailScreenState();
}

class _GymerDetailScreenState extends State<GymerDetailScreen> {
  final _gymerRepo = GymersRepository();
  final _plansRepo = WorkoutPlansRepository();
  final _trainingRepo = TrainingRequestsRepository();
  final _currentRepo = CurrentUserRepository();

  GymerDetailModel? _detail;
  bool _loadingDetail = true;
  String? _detailError;

  bool _plansLoading = true;
  String? _plansError;
  List<WorkoutPlanModel> _plans = [];

  String? _acceptedTrainingRequestId;
  bool _trainingLoading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadDetail(), _resolveTrainingRelation()]);
    await _loadPlans();
  }

  Future<void> _resolveTrainingRelation() async {
    setState(() => _trainingLoading = true);
    try {
      final profile = await _currentRepo.fetchProfile();
      if (profile?.role == 'COACH') {
        final roleEntity = await _currentRepo.fetchRoleEntity();
        if (roleEntity is CoachByUserResult) {
          final list = await _trainingRepo.fetch(
            coachId: roleEntity.id,
            gymerId: widget.gymerId,
          );
          // Find ACCEPTED training request (list may be empty) without using firstWhere + null orElse
          for (final r in list) {
            if (r.status == 'ACCEPTED') {
              _acceptedTrainingRequestId = r.id;
              break;
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _trainingLoading = false);
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });
    try {
      final d = await _gymerRepo.fetchByUserId(widget.userId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = 'Lỗi: $e';
        _loadingDetail = false;
      });
    }
  }

  Future<void> _loadPlans() async {
    setState(() {
      _plansLoading = true;
      _plansError = null;
    });
    try {
      final all = await _plansRepo.getPlansByUser(widget.userId);
      // Filter strictly by accepted trainingRequestId if available
      final filtered = (_acceptedTrainingRequestId == null)
          ? <WorkoutPlanModel>[]
          : all
                .where((p) => p.trainingRequestId == _acceptedTrainingRequestId)
                .toList();
      if (!mounted) return;
      setState(() {
        _plans = filtered;
        _plansLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plansError = 'Lỗi tải kế hoạch: $e';
        _plansLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _loadingDetail && _detail == null
            ? _skeleton()
            : _detailError != null && _detail == null
            ? _errorView()
            : _content(),
      ),
    );
  }

  Widget _content() {
    final user = _detail!.user;
    final name = (user?['name'] as String?) ?? '—';
    final avatar = _detail!.pictureProfile ?? user?['profilePicture'];
    final goal = _detail!.goal;
    final bio = (user?['biography'] as String?)?.trim();
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3A3A3D), Color(0xFF1B1B1D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Gymer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _bootstrap,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ProfileAvatar(
                imageUrl: avatar,
                size: 120,
                heroTag: 'gymer_avatar_${widget.gymerId}',
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                _bioSection(bio),
              ],
              if (goal != null && goal.isNotEmpty) ...[
                const SizedBox(height: 12),
                _goalChip(goal),
              ],
              const SizedBox(height: 14),
              _chipsRow(),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.50,
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.45),
                  blurRadius: 32,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kế hoạch tập cho gymer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _buildAddPlanButton(),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: RefreshIndicator(
                    color: Colors.orange,
                    onRefresh: () async {
                      await _loadDetail();
                      await _resolveTrainingRelation();
                      await _loadPlans();
                    },
                    child: _buildPlansPanel(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPlanButton() {
    final disabled = _acceptedTrainingRequestId == null || _trainingLoading;
    return Tooltip(
      message: disabled
          ? 'Cần có hợp đồng đã chấp nhận để tạo kế hoạch'
          : 'Tạo kế hoạch mới',
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: disabled
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chưa có hợp đồng ACCEPTED với gymer.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateWorkoutPlanScreen(
                      userId: widget.userId,
                      trainingRequestId: _acceptedTrainingRequestId,
                    ),
                  ),
                );
                if (created != null) {
                  // reload plans (and update chips count)
                  await _loadPlans();
                }
              },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: disabled
                ? Colors.white.withOpacity(.05)
                : Colors.orange.withOpacity(.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: disabled
                  ? Colors.white.withOpacity(.12)
                  : Colors.orange.withOpacity(.65),
              width: 1.1,
            ),
          ),
          child: Icon(
            Icons.add_rounded,
            size: 22,
            color: disabled ? Colors.white54 : Colors.orange,
          ),
        ),
      ),
    );
  }

  Widget _goalChip(String goal) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white.withOpacity(.06),
      border: Border.all(color: Colors.white.withOpacity(.14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flag_rounded, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Text(
          goal,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          ),
        ),
      ],
    ),
  );

  Widget _buildPlansPanel() {
    if (_trainingLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    if (_acceptedTrainingRequestId == null) {
      return Center(
        child: Text(
          'Chưa có hợp đồng đã được chấp nhận với gymer này.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 13),
        ),
      );
    }
    if (_plansLoading) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => _planSkeletonVertical(),
      );
    }
    if (_plansError != null) {
      return _errorBlock(_plansError!, onRetry: _loadPlans);
    }
    if (_plans.isEmpty) {
      return _emptyPlans();
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 120),
      itemCount: _plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) {
        final p = _plans[i];
        return WorkoutCard(
          image: p.picture ?? '',
          title: p.name,
          subtitle: '${p.days} ngày',
          planType: p.planType,
          badge: p.planType,
          description: p.description,
          // full-size (compact: false)
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutDetailScreen(
                  planId: p.id,
                  image: p.picture ?? '',
                  title: p.name,
                  subtitle: '${p.days} ngày',
                  description: p.description,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyPlans() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
      decoration: _planDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.view_timeline_rounded,
            size: 46,
            color: Colors.white.withOpacity(.28),
          ),
          const SizedBox(height: 18),
          Text(
            'Chưa có workout plan nào',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.82),
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bạn có thể tạo kế hoạch tập riêng cho gymer này để theo dõi tiến trình tốt hơn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.55),
              fontSize: 12.8,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _acceptedTrainingRequestId == null
                ? 'Chưa thể tạo: cần hợp đồng đã ACCEPTED (nút + sẽ tự mở khi sẵn sàng)'
                : 'Nhấn nút + phía trên bên phải để tạo kế hoạch đầu tiên',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.40),
              fontSize: 12.2,
              height: 1.3,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Legacy detailed card removed; using WorkoutCard instead

  // Removed old vertical skeleton layout (_planSkeleton)

  Widget _planSkeletonVertical() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: _skeletonBox(borderRadius: 0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 180, decoration: _skeletonBox()),
                const SizedBox(height: 10),
                Container(height: 12, width: 120, decoration: _skeletonBox()),
                const SizedBox(height: 12),
                Container(height: 12, width: 90, decoration: _skeletonBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bioSection(String bio) => Text(
    bio,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: Colors.white.withOpacity(.75),
      fontSize: 13,
      height: 1.35,
    ),
  );

  Widget _chipsRow() {
    return Row(
      children: [
        _smallChip('Gymer'),
        const SizedBox(width: 8),
        _smallChip(_plansLoading ? 'Plans: …' : 'Plans: ${_plans.length}'),
      ],
    );
  }

  Widget _smallChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(.10)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(.78),
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: .2,
      ),
    ),
  );

  BoxDecoration _planDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      colors: [Color(0xFF1B1B1E), Color(0xFF24242A), Color(0xFF2F2F37)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: Colors.white.withOpacity(.08)),
  );

  // Removed _planIcon (not needed in horizontal compact layout)

  // (Removed old meta chip & relative time helpers – handled by WorkoutCard subtitle)

  Widget _errorBlock(String msg, {VoidCallback? onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: _planDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Colors.redAccent.shade200,
          ),
          const SizedBox(height: 14),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _skeletonBox({double borderRadius = 8}) => BoxDecoration(
    borderRadius: BorderRadius.circular(borderRadius),
    gradient: const LinearGradient(
      colors: [Color(0xFF2A2A2E), Color(0xFF26262B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  Widget _skeleton() => const Center(
    child: Padding(
      padding: EdgeInsets.only(top: 80),
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent.shade200, size: 42),
          const SizedBox(height: 16),
          Text(
            _detailError ?? 'Lỗi không xác định',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.75),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _bootstrap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? heroTag;
  const _ProfileAvatar({this.imageUrl, required this.size, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final avatarCore = _buildCore();
    return heroTag != null
        ? Hero(tag: heroTag!, child: avatarCore)
        : avatarCore;
  }

  Widget _buildCore() {
    final gradient = const LinearGradient(
      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A00E0).withOpacity(.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(Icons.person, color: Colors.white, size: size * .46),
      );
    }
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A00E0).withOpacity(.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.white.withOpacity(.1),
            alignment: Alignment.center,
            child: Icon(Icons.person, color: Colors.white, size: size * .42),
          ),
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.white.withOpacity(.05),
              alignment: Alignment.center,
              child: SizedBox(
                width: size * .3,
                height: size * .3,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
