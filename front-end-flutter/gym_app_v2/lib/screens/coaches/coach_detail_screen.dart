import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/coaches_repository.dart';
import '../../repositories/feedbacks_repository.dart';
import '../../repositories/current_user_repository.dart';
import '../../repositories/training_requests_repository.dart';
import '../../repositories/appointments_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/appointment_scheduler_bottom_sheet.dart';
import '../../models/coach_model.dart';
import '../../models/feedback_model.dart';
import '../chat/chat_screen.dart';

class CoachDetailScreen extends StatefulWidget {
  final String coachId;
  final CoachModel? initial;
  const CoachDetailScreen({super.key, required this.coachId, this.initial});

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  final _repo = CoachesRepository();
  final _feedbackRepo = FeedbacksRepository();
  final _currentUserRepo = CurrentUserRepository();
  final _trainingRepo = TrainingRequestsRepository();
  final _appointmentsRepo = AppointmentsRepository();
  CoachModel? _coach;
  bool _loading = true;
  bool _error = false;
  String? _errorMsg;

  // Feedback state
  bool _fbLoading = false;
  bool _fbError = false;
  String? _fbErrorMsg;
  List<FeedbackModel> _feedbacks = [];

  // Current user context
  String? _currentUserId;
  String? _currentUserRole; // COACH | GYMER | ADMIN
  String? _currentUserName;

  // Training request state
  bool _trainingLoading = false; // spinner for indicator
  bool? _trainingAccepted; // null => not loaded or not gymer
  bool _hasAcceptedElsewhere =
      false; // already has an accepted contract with another coach
  String? _acceptedTrainingRequestId; // track id to allow cancellation

  @override
  void initState() {
    super.initState();
    // If initial coach given, use it while refreshing in background
    if (widget.initial != null) {
      _coach = widget.initial;
      _loading = false;
      // still perform a refresh to get latest data
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    } else {
      _fetch();
    }
    _bootstrapCurrentUser();
  }

  Future<void> _bootstrapCurrentUser() async {
    final profile = await _currentUserRepo.fetchProfile();
    if (!mounted) return;
    setState(() {
      _currentUserId = profile?.id;
      _currentUserRole = profile?.role;
      _currentUserName = profile?.name;
    });
    // If gymer, load training status + eligibility
    if (profile?.role == 'GYMER') {
      final roleEntity = await _currentUserRepo.fetchRoleEntity();
      if (!mounted) return;
      if (roleEntity is GymerByUserResult) {
        _fetchTrainingStatus(gymerId: roleEntity.id, coachId: widget.coachId);
        _checkTrainingEligibility(roleEntity.id);
      }
    }
  }

  Future<void> _fetchTrainingStatus({
    required String gymerId,
    required String coachId,
  }) async {
    setState(() {
      _trainingLoading = true;
    });
    final list = await _trainingRepo.fetch(gymerId: gymerId, coachId: coachId);
    if (!mounted) return;
    final acceptedItem = list.where((r) => r.status == 'ACCEPTED').toList();
    final accepted = acceptedItem.isNotEmpty;
    setState(() {
      _trainingAccepted = accepted;
      _acceptedTrainingRequestId = accepted ? acceptedItem.first.id : null;
      _trainingLoading = false;
    });
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMsg = null;
    });
    final data = await _repo.fetchById(
      widget.coachId,
      forceRefresh: _coach == null,
    );
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _error = true;
        _errorMsg = 'Không tải được thông tin huấn luyện viên';
        _loading = false;
      });
    } else {
      setState(() {
        _coach = data;
        _loading = false;
      });
    }
    // After coach loaded, load feedbacks
    if (data != null) _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks({bool force = false}) async {
    final coachId = widget.coachId;
    setState(() {
      _fbLoading = true;
      _fbError = false;
      _fbErrorMsg = null;
    });
    final list = await _feedbackRepo.fetchByCoach(coachId, forceRefresh: force);
    if (!mounted) return;
    setState(() {
      _feedbacks = list;
      _fbLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final coach = _coach;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _loading && coach == null
            ? _skeleton()
            : _error && coach == null
            ? _errorView()
            : _content(coach!),
      ),
    );
  }

  Widget _content(CoachModel coach) {
    final name = coach.user?.name ?? '—';
    final bio = (coach.user?.biography?.trim().isNotEmpty ?? false)
        ? coach.user!.biography!.trim()
        : 'Chưa có mô tả.';
    final rating = (coach.averageRating ?? 0).toStringAsFixed(1);
    final trainings = coach.appointmentsCount;
    final gymers = coach.trainingRequestsSentCount; // placeholder
    final rateCount = coach.feedbacksCount;

    return Stack(
      children: [
        // Full background gradient covers entire screen (eliminates black gap)
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
        // Header with reserved avatar space (transparent now)
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
                    'Huấn luyện viên',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildTopRightMenu(),
                ],
              ),
              const SizedBox(height: 10),
              _CoachProfileAvatar(
                imageUrl: coach.user?.profilePicture,
                size: 120,
                heroTag: 'coach_avatar_${coach.id}',
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
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _bioSection(bio)),
                  if (_trainingAccepted == true) ...[
                    const SizedBox(width: 12),
                    _ScheduleAppointmentButton(
                      onTap: () {
                        _openScheduleAppointmentFlow();
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_currentUserRole != 'COACH') _trainingRequestIndicator(),
                  const SizedBox(width: 12),
                  _roundButton(
                    icon: Icons.message,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            coachName: name,
                            coachImage: coach.user?.profilePicture ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem('$trainings', 'Trainings'),
                        _statItem('$gymers', 'Gymers'),
                        _statItem(rating, 'Rate'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Fixed feedback panel (sits above gradient)
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Rate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ratingBadge(rating, rateCount),
                      ],
                    ),
                    _commentButton(disabled: _isCommentDisabled()),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildFeedbackList()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopRightMenu() {
    final canCancel =
        _trainingAccepted == true &&
        _acceptedTrainingRequestId != null &&
        _currentUserRole == 'GYMER';
    if (!canCancel) {
      return const SizedBox(
        width: 48,
      ); // keep layout balance with back button width
    }
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'cancel') {
          _confirmCancelContract();
        }
      },
      color: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(
        0,
        12,
      ), // push menu downward so it doesn't overlay title
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'cancel',
          child: Text('Hủy hợp đồng', style: TextStyle(color: Colors.white)),
        ),
      ],
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.more_vert, color: Colors.white),
      ),
    );
  }

  Future<void> _confirmCancelContract() async {
    final id = _acceptedTrainingRequestId;
    if (id == null) return;
    bool submitting = false;
    await showDialog(
      context: context,
      barrierDismissible: !submitting,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Hủy hợp đồng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'Bạn chắc chắn muốn hủy hợp đồng huấn luyện này?\n\nHành động này sẽ chấm dứt quyền truy cập vào các kế hoạch luyện tập liên quan (nếu có).',
                style: TextStyle(
                  color: Colors.white.withOpacity(.75),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          setSt(() => submitting = true);
                          final ok = await _trainingRepo.remove(id: id);
                          if (!mounted) return;
                          Navigator.pop(ctx, ok);
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Xác nhận',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((ok) async {
      if (ok == true) {
        // Refresh training status (will clear accepted id)
        final roleEntity = await _currentUserRepo.fetchRoleEntity();
        if (roleEntity is GymerByUserResult) {
          await _fetchTrainingStatus(
            gymerId: roleEntity.id,
            coachId: widget.coachId,
          );
          await _checkTrainingEligibility(roleEntity.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy hợp đồng thành công'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Widget _bioSection(String bio) {
    return Text(
      bio,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.start,
      style: TextStyle(
        color: Colors.white.withOpacity(.75),
        fontSize: 13,
        height: 1.35,
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(.08),
          border: Border.all(color: Colors.white.withOpacity(.1), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _trainingRequestIndicator() {
    // If still loading training status
    if (_trainingLoading) {
      return Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(.08),
          border: Border.all(color: Colors.white.withOpacity(.1), width: 1),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }
    // If no data loaded (e.g., user not gymer), hide
    if (_trainingAccepted == null) {
      return const SizedBox.shrink();
    }
    if (_trainingAccepted == true) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.withOpacity(.18),
          border: Border.all(color: Colors.green.withOpacity(.4), width: 1),
        ),
        child: const Icon(Icons.check, color: Colors.greenAccent, size: 28),
      );
    }
    if (_hasAcceptedElsewhere) {
      return const SizedBox.shrink();
    }
    return _roundButton(
      icon: Icons.add,
      onTap: _openCreateTrainingRequestDialog,
    );
  }

  Future<void> _checkTrainingEligibility(String gymerId) async {
    final anyAccepted = await _trainingRepo.hasAnyAcceptedElsewhere(
      gymerId: gymerId,
    );
    if (!mounted) return;
    setState(() => _hasAcceptedElsewhere = anyAccepted);
  }

  Future<void> _openCreateTrainingRequestDialog() async {
    final roleEntity = await _currentUserRepo.fetchRoleEntity();
    if (roleEntity is! GymerByUserResult) return;
    if (_hasAcceptedElsewhere) return; // already in a contract
    bool submitting = false;
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30));
    final coachName = _coach?.user?.name ?? 'Coach';
    final price = _coach?.trainingPrice;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101012),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 20 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 20),
                  const Text(
                    'Xác nhận hợp đồng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _contractInfoRow(
                    'Gymer',
                    (_currentUserName != null && _currentUserName!.isNotEmpty)
                        ? _currentUserName!
                        : 'Gymer',
                  ),
                  _contractInfoRow('Coach', coachName),
                  // Start date row
                  _contractInfoRow('Bắt đầu', _formatDateTime(now)),
                  // End date row
                  _contractInfoRow('Kết thúc', _formatDateTime(endDate)),
                  if (price != null)
                    _contractInfoRow('Giá', '${price.toStringAsFixed(0)} đ'),
                  const SizedBox(height: 26),
                  AppButton.primary(
                    label: 'Đồng ý',
                    onPressed: submitting
                        ? null
                        : () async {
                            setSt(() => submitting = true);
                            final created = await _trainingRepo.create(
                              gymerId: roleEntity.id,
                              coachId: widget.coachId,
                              trainingDate: now.toUtc(),
                            );
                            if (!mounted) return;
                            if (created != null) {
                              Navigator.pop(ctx, true);
                            } else {
                              setSt(() => submitting = false);
                            }
                          },
                    loading: submitting,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 12),
                  AppButton.outline(
                    label: 'Hủy',
                    onPressed: submitting
                        ? null
                        : () => Navigator.pop(ctx, false),
                    fullWidth: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((success) async {
      if (success == true) {
        final roleEntity2 = await _currentUserRepo.fetchRoleEntity();
        if (roleEntity2 is GymerByUserResult) {
          await _fetchTrainingStatus(
            gymerId: roleEntity2.id,
            coachId: widget.coachId,
          );
          await _checkTrainingEligibility(roleEntity2.id);
        }
        setState(() {});
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _contractInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(.55),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 12),
        ),
      ],
    );
  }

  Widget _ratingBadge(String rating, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFFFB347), size: 18),
          const SizedBox(width: 4),
          Text(
            '$rating/$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isCommentDisabled() {
    if (_currentUserId == null) return false; // cannot determine
    // Disable if current user is this coach user OR has a feedback either as gymer or coach participant
    final coachUserId = _coach?.user?.id;
    final already = _feedbacks.any(
      (f) =>
          f.gymer?.user?.id == _currentUserId ||
          f.coach?.user?.id == _currentUserId,
    );
    // Also disable if training not accepted (must have ACCEPTED training request)
    final notAccepted = _trainingAccepted != true;
    return _currentUserId == coachUserId || already || notAccepted;
  }

  bool _canModifyFeedback(FeedbackModel f) {
    // User must be feedback author (gymer side) and have accepted training (already required to leave feedback)
    final uid = _currentUserId;
    if (uid == null) return false;
    final isAuthor = f.gymer?.user?.id == uid;
    return isAuthor;
  }

  Widget _commentButton({bool disabled = false}) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A00E0).withOpacity(.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : () => _openFeedbackDialog(),
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              child: Text(
                'Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewCard({
    required String name,
    required String comment,
    required int rating,
    required String date,
    FeedbackModel? model,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.07), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.white.withOpacity(.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (model != null && _canModifyFeedback(model))
                      _feedbackMenu(model),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.75),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (i) {
                    final filled = i < rating;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 16,
                        color: filled
                            ? const Color(0xFFFFB347)
                            : Colors.white24,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFeedbackDialog() async {
    if (_coach == null || _currentUserId == null) return;
    // Need gymer id to post (current user must be gymer). For now attempt fetch role entity again.
    final roleEntity = await _currentUserRepo.fetchRoleEntity();
    String? gymerId;
    if (roleEntity is GymerByUserResult) gymerId = roleEntity.id;
    if (gymerId == null) {
      // Not a gymer – ignore
      return;
    }
    double tempRating = 5;
    final controller = TextEditingController();
    bool submitting = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101012),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < tempRating.round();
                      return GestureDetector(
                        onTap: submitting
                            ? null
                            : () =>
                                  setSt(() => tempRating = (i + 1).toDouble()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 30,
                            color: const Color(0xFFFFB347),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: controller,
                      enabled: !submitting,
                      maxLines: 5,
                      minLines: 4,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your comment ...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(.4),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 46,
                    child: AppButton.primary(
                      label: 'Comment',
                      loading: submitting,
                      onPressed: submitting
                          ? null
                          : () async {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;
                              setSt(() => submitting = true);
                              final created = await _feedbackRepo
                                  .createFeedback(
                                    gymerId: gymerId!,
                                    coachId: _coach!.id,
                                    rating: tempRating.clamp(1, 5),
                                    content: text,
                                  );
                              if (!mounted) return;
                              if (created != null) {
                                Navigator.pop(ctx, true);
                              } else {
                                setSt(() => submitting = false);
                              }
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((success) async {
      if (success == true) {
        // Refresh list (force)
        await _fetchFeedbacks(force: true);
        setState(() {}); // to re-evaluate disabled state
      }
    });
  }

  Widget _buildFeedbackList() {
    if (_fbLoading) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(bottom: i == 2 ? 0 : 14),
          child: Container(
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.05),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.08),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.white.withOpacity(.1),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: double.infinity,
                        color: Colors.white.withOpacity(.06),
                      ),
                      const Spacer(),
                      Container(
                        height: 10,
                        width: 90,
                        color: Colors.white.withOpacity(.08),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_fbError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fbErrorMsg ?? 'Lỗi tải đánh giá',
              style: TextStyle(color: Colors.white.withOpacity(.7)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _fetchFeedbacks(force: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_feedbacks.isEmpty) {
      return Center(
        child: Text(
          'Chưa có đánh giá nào',
          style: TextStyle(color: Colors.white.withOpacity(.6)),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _feedbacks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final f = _feedbacks[i];
        final name = f.gymer?.user?.name ?? '—';
        final comment = f.content ?? '';
        final dateStr =
            '${f.createdAt.day}/${f.createdAt.month}/${f.createdAt.year}';
        return _reviewCard(
          name: name,
          comment: comment,
          rating: f.rating,
          date: dateStr,
          model: f,
        );
      },
    );
  }

  Widget _feedbackMenu(FeedbackModel f) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 'edit') {
          _openEditFeedbackDialog(f);
        } else if (v == 'delete') {
          _confirmDeleteFeedback(f);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Xóa', style: TextStyle(color: Colors.white)),
        ),
      ],
      child: Icon(
        Icons.more_vert,
        color: Colors.white.withOpacity(.7),
        size: 18,
      ),
    );
  }

  Future<void> _openEditFeedbackDialog(FeedbackModel f) async {
    double tempRating = f.rating.toDouble();
    final controller = TextEditingController(text: f.content ?? '');
    bool submitting = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101012),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'Chỉnh sửa feedback',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < tempRating.round();
                      return GestureDetector(
                        onTap: submitting
                            ? null
                            : () =>
                                  setSt(() => tempRating = (i + 1).toDouble()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 28,
                            color: const Color(0xFFFFB347),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: controller,
                      enabled: !submitting,
                      maxLines: 5,
                      minLines: 4,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập nội dung...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(.4),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: AppButton.primary(
                      label: 'Lưu',
                      loading: submitting,
                      onPressed: submitting
                          ? null
                          : () async {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;
                              setSt(() => submitting = true);
                              final updated = await _feedbackRepo
                                  .updateFeedback(
                                    feedbackId: f.id,
                                    coachId: _coach!.id,
                                    rating: tempRating.clamp(1, 5),
                                    content: text,
                                  );
                              if (!mounted) return;
                              if (updated != null) {
                                Navigator.pop(ctx, true);
                              } else {
                                setSt(() => submitting = false);
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: AppButton.outline(
                      label: 'Hủy',
                      onPressed: submitting
                          ? null
                          : () => Navigator.pop(ctx, false),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((success) async {
      if (success == true) {
        setState(() {}); // data already updated in cache; force rebuild
      }
    });
  }

  Future<void> _confirmDeleteFeedback(FeedbackModel f) async {
    bool deleting = false;
    await showDialog(
      context: context,
      barrierDismissible: !deleting,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Xóa feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              content: Text(
                'Bạn chắc chắn muốn xóa feedback này?',
                style: TextStyle(
                  color: Colors.white.withOpacity(.75),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: deleting ? null : () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: deleting
                      ? null
                      : () async {
                          setSt(() => deleting = true);
                          final ok = await _feedbackRepo.deleteFeedback(
                            feedbackId: f.id,
                            coachId: _coach!.id,
                          );
                          if (!mounted) return;
                          Navigator.pop(ctx, ok);
                        },
                  child: deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Xóa',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((ok) async {
      if (ok == true) {
        // Rebuild list after deletion
        await _fetchFeedbacks(force: true);
        setState(() {});
      }
    });
  }
  // Removed old metric/expertise/section/action widgets (streamlined per Figma)

  Widget _skeleton() {
    return Column(
      children: [
        const SizedBox(height: 80),
        const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ],
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.redAccent.shade200,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMsg ?? 'Lỗi không xác định',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
              ),
              onPressed: () {},
              child: AppButton.primary(label: 'Thử lại', onPressed: _fetch),
            ),
          ],
        ),
      ),
    );
  }

  void _openScheduleAppointmentFlow() async {
    if (_trainingAccepted != true) return; // guard

    // Fetch gymer id
    final roleEntity = await _currentUserRepo.fetchRoleEntity();
    if (roleEntity is! GymerByUserResult) return;
    final gymerId = roleEntity.id;

    // Load confirmed appointments for this coach to disable those days
    final booked = await _appointmentsRepo.fetchConfirmedByCoach(
      widget.coachId,
    );

    // Show the bottom sheet
    AppointmentSchedulerBottomSheet.show(
      context: context,
      coachId: widget.coachId,
      gymerId: gymerId,
      bookedAppointments: booked,
      onSuccess: () {
        // Optional: refresh something when appointment is created successfully
      },
    );
  }
}

class _CoachProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? heroTag;
  const _CoachProfileAvatar({
    required this.imageUrl,
    required this.size,
    this.heroTag,
  });

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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white70,
                  ),
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1)
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScheduleAppointmentButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScheduleAppointmentButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A00E0).withOpacity(.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.event_available, color: Colors.white, size: 22),
      ),
    );
  }
}
