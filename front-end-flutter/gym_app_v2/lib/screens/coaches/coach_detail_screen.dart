import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/coaches_repository.dart';
import '../../models/coach_model.dart';
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
  CoachModel? _coach;
  bool _loading = true;
  bool _error = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _coach = widget.initial;
    _fetch();
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
    final ratingVal = (coach.averageRating ?? 0).toStringAsFixed(1);
    final trainings = coach.appointmentsCount; // using appointments as proxy
    final gymers =
        coach.trainingRequestsSentCount; // or different count if available
    final rateCount = coach.feedbacksCount;
    // Figma layout: large header with overlay stats row + below: Rate section + reviews list

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 370,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3A3A3D), Color(0xFF1B1B1D)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Top bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 4,
                  left: 4,
                  right: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Huấn luyện viên của tôi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Avatar
                Align(
                  alignment: const Alignment(0, -0.15),
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.55),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 86,
                    ),
                  ),
                ),
                // Name + subtitle + actions + stats row
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PT cá nhân',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.75),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _roundButton(icon: Icons.add, onTap: () {}),
                          const SizedBox(width: 14),
                          _roundButton(
                            icon: Icons.message,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    coachName: name,
                                    coachImage:
                                        coach.user?.profilePicture ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(child: _statItem('$trainings', 'Trainings')),
                          Expanded(child: _statItem('$gymers', 'Gymers')),
                          Expanded(child: _statItem(ratingVal, 'Rate')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Rate section
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
                      _ratingBadge(ratingVal, rateCount),
                    ],
                  ),
                  _commentButton(),
                ],
              ),
              const SizedBox(height: 18),
              // Reviews placeholder list (static for now)
              _reviewCard(
                name: 'Quỳnh Như',
                comment: 'Huấn luyện viên rất tốt',
                rating: 5,
                date: '4/4/2025',
              ),
              const SizedBox(height: 14),
              _reviewCard(
                name: 'Quỳnh Thu',
                comment: 'Huấn luyện viên tạm được',
                rating: 4,
                date: '4/4/2025',
              ),
              const SizedBox(height: 14),
              _reviewCard(
                name: 'Trâm Anh',
                comment: 'Huấn luyện viên rất tốt',
                rating: 5,
                date: '4/4/2025',
              ),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
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

  Widget _commentButton() {
    return Container(
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
          onTap: () {},
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            child: Text(
              'Comment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.45),
                        fontSize: 11,
                      ),
                    ),
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
                backgroundColor: Colors.redAccent.withOpacity(.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              onPressed: _fetch,
              child: const Text(
                'Thử lại',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
