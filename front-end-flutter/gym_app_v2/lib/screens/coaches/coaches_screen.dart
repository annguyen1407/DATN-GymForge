import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'coach_detail_screen.dart';
import '../../repositories/coaches_repository.dart';
import '../../models/coach_model.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  final List<CoachModel> _all = [];
  final _repo = CoachesRepository();
  bool _loading = false;
  bool _error = false;
  String? _errorMessage;
  // Removed old load-more state; numbered pagination in use
  // Numbered pagination state (first page has different size)
  int _currentPage = 1; // 1-based
  static const int _firstPageSize = 4; // rest cards shown on first page
  static const int _otherPageSize = 6; // rest cards per subsequent page
  int _totalPages = 1; // computed after data load
  List<CoachModel> _cachedFull = [];
  CoachesQuery _query = const CoachesQuery(
    sortBy: 'rating',
    sortOrder: 'desc',
    isOpenToTraining: true,
  );

  @override
  void initState() {
    super.initState();
    _fetch(initial: true);
  }

  Future<void> _fetch({bool initial = false, bool refresh = false}) async {
    if (_loading) return;
    if (initial) {
      setState(() {
        _loading = true;
        _error = false;
        _errorMessage = null;
      });
    } else if (refresh) {
      setState(() {
        _error = false;
        _errorMessage = null;
      });
    }
    try {
      // Fetch full list once (backend paging not yet used) and derive pages client-side.
      final fullList = await _repo.fetch(
        _query,
        forceRefresh: initial || refresh,
      );
      if ((fullList.isEmpty) && _cachedFull.isEmpty) {
        setState(() {
          _error = true;
          _errorMessage = 'Không có dữ liệu';
        });
      } else {
        setState(() {
          if (initial || refresh) {
            _cachedFull = fullList;
            _recomputeTotalPages();
            _currentPage = 1;
            _rebuildPagedList();
          } else {
            // Not used: no incremental load-more in numbered mode
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _recomputeTotalPages() {
    // Exclude top2 from pagination base if we have more than 2
    final restCount = _cachedFull.length > 2 ? _cachedFull.length - 2 : 0;
    if (restCount <= 0) {
      _totalPages = 1;
    } else if (restCount <= _firstPageSize) {
      // All fit into first page
      _totalPages = 1;
    } else {
      final remaining = restCount - _firstPageSize;
      final additionalPages = (remaining / _otherPageSize).ceil();
      _totalPages = 1 + additionalPages;
    }
    if (_totalPages < 1) _totalPages = 1;
    if (_currentPage > _totalPages) _currentPage = _totalPages;
  }

  void _rebuildPagedList() {
    _all
      ..clear()
      ..addAll(
        _cachedFull,
      ); // Keep full for top2 slicing; list view will slice per page
    setState(() {});
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  Future<void> _refresh() async {
    await _fetch(initial: true, refresh: true);
  }

  // Pagination placeholder removed (backend currently returns full set)

  @override
  Widget build(BuildContext context) {
    final top2 = _all.take(2).toList();
    final restAll = _all.length > 2 ? _all.sublist(2) : <CoachModel>[];
    final pagedRest = _paginateRest(restAll);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Huấn luyện viên',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: _loading ? null : () => _refresh(),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: Colors.purpleAccent,
          child: _buildBody(top2, pagedRest),
        ),
      ),
    );
  }

  Widget _buildBody(List<CoachModel> top2, List<CoachModel> rest) {
    if (_loading && _all.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Huấn luyện viên nổi bật'),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _CoachTopSkeleton()),
              SizedBox(width: 16),
              Expanded(child: _CoachTopSkeleton()),
            ],
          ),
          const SizedBox(height: 32),
          _sectionTitle('Tất cả huấn luyện viên'),
          const SizedBox(height: 16),
          for (int i = 0; i < 5; i++) const _CoachListSkeleton(),
        ],
      );
    }
    if (_error && _all.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [_errorBox()],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_currentPage == 1 && top2.isNotEmpty)
          _sectionTitle('Huấn luyện viên nổi bật'),
        if (_currentPage == 1 && top2.isNotEmpty) const SizedBox(height: 16),
        if (_currentPage == 1 && top2.isNotEmpty)
          Row(
            children: [
              for (int i = 0; i < top2.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: _buildTopCoachCard(top2[i], i == 0)),
              ],
            ],
          ),
        if (_currentPage == 1 && top2.isNotEmpty) const SizedBox(height: 32),
        _sectionTitle('Tất cả huấn luyện viên'),
        const SizedBox(height: 16),
        if (rest.isEmpty && top2.isEmpty && !_loading) _emptyState(),
        for (final c in rest) ...[
          _buildCoachListItem(c),
          const SizedBox(height: 12),
        ],
        if (!_loading && rest.isNotEmpty) _paginationBar(),
        const SizedBox(height: 40),
      ],
    );
  }

  List<CoachModel> _paginateRest(List<CoachModel> restAll) {
    // On page 1, show first slice; subsequent pages show appropriate segment
    if (restAll.isEmpty) return restAll;
    if (_currentPage == 1) {
      final end = _firstPageSize < restAll.length
          ? _firstPageSize
          : restAll.length;
      return restAll.sublist(0, end);
    }
    // Adjust for first page chunk
    final afterFirst = restAll.skip(_firstPageSize).toList();
    final idxPage = _currentPage - 2; // zero-based index among subsequent pages
    final start = idxPage * _otherPageSize;
    final end = start + _otherPageSize;
    final safeStart = start < 0
        ? 0
        : (start > afterFirst.length ? afterFirst.length : start);
    final safeEnd = end < 0
        ? 0
        : (end > afterFirst.length ? afterFirst.length : end);
    return afterFirst.sublist(safeStart, safeEnd);
  }

  Widget _paginationBar() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    final items = _buildPaginationItems();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: items,
      ),
    );
  }

  List<Widget> _buildPaginationItems() {
    final List<Widget> widgets = [];
    // Helper to add button
    void addBtn(int p) {
      final isCurrent = p == _currentPage;
      widgets.add(
        GestureDetector(
          onTap: isCurrent ? null : () => _goToPage(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: isCurrent
                  ? const LinearGradient(
                      colors: [Color(0xFF4E4376), Color(0xFF2B5876)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF26262A), Color(0xFF1E1E21)],
                    ),
              border: Border.all(
                color: Colors.white.withOpacity(isCurrent ? .25 : .08),
                width: 1,
              ),
            ),
            child: Text(
              '$p',
              style: TextStyle(
                color: Colors.white.withOpacity(isCurrent ? .95 : .65),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                letterSpacing: .2,
              ),
            ),
          ),
        ),
      );
    }

    // Generate sequence with ellipses
    final int total = _totalPages;
    final int current = _currentPage;
    List<int> corePages = [];
    if (total <= 7) {
      corePages = List.generate(total, (i) => i + 1);
    } else {
      corePages.add(1);
      corePages.add(2);
      final startWindow = (current - 1).clamp(3, total - 2);
      final endWindow = (current + 1).clamp(3, total - 2);
      for (int p = startWindow; p <= endWindow; p++) {
        corePages.add(p);
      }
      corePages.add(total - 1);
      corePages.add(total);
      corePages = corePages.toSet().toList()..sort();
    }

    int? prev;
    for (final p in corePages) {
      if (prev != null && p - prev > 1) {
        widgets.add(_ellipsis());
      }
      addBtn(p);
      prev = p;
    }
    return widgets;
  }

  Widget _ellipsis() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Text(
      '…',
      style: TextStyle(
        color: Colors.white.withOpacity(.45),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _errorBox() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF2A0E0E), Color(0xFF3A1A1A)],
      ),
      border: Border.all(color: Colors.red.withOpacity(.4), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Không tải được danh sách',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Lỗi không xác định',
          style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 12),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.redAccent.withOpacity(.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () => _fetch(initial: true),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text(
            'Thử lại',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF1B1B1D), Color(0xFF232327), Color(0xFF28282D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: Colors.white.withOpacity(.05), width: 1),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4E4376), Color(0xFF2B5876)],
            ),
          ),
          child: const Icon(
            Icons.person_search_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chưa có huấn luyện viên',
                style: TextStyle(
                  color: Colors.white.withOpacity(.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hãy thử thay đổi bộ lọc để tìm thêm.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.55),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildTopCoachCard(CoachModel coach, bool primary) {
    final rating = coach.averageRating ?? 0;
    return GestureDetector(
      onTap: () => _openDetail(coach),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: primary
                ? const [Color(0xFF4E4376), Color(0xFF2B5876)]
                : const [Color(0xFF2E2E33), Color(0xFF26262A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
          boxShadow: [
            if (primary)
              BoxShadow(
                color: const Color(0xFF4E4376).withOpacity(.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          children: [
            _CoachAvatar(url: coach.user?.profilePicture, size: 84),
            const SizedBox(height: 12),
            Text(
              coach.user?.name ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.95),
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.orange.shade400,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${coach.feedbacksCount} đánh giá',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachListItem(CoachModel coach) {
    final rating = coach.averageRating ?? 0;
    return GestureDetector(
      onTap: () => _openDetail(coach),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B1B1D), Color(0xFF26262A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(.06), width: 1),
        ),
        child: Row(
          children: [
            _CoachAvatar(url: coach.user?.profilePicture, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.user?.name ?? '—',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.92),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: [
                      if (coach.trainingPrice != null)
                        _tag(
                          '${coach.trainingPrice!.toStringAsFixed(0)} VNĐ/Gói tập',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.orange.shade400,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4E4376), Color(0xFF2B5876)],
                    ),
                  ),
                  child: const Text(
                    'Xem',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.07),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(.7),
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  void _openDetail(CoachModel coach) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachDetailScreen(coachId: coach.id, initial: coach),
      ),
    );
  }
}

class _CoachTopSkeleton extends StatelessWidget {
  const _CoachTopSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF242428), Color(0xFF1C1C1F)],
        ),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.07),
            ),
          ),
          const SizedBox(height: 16),
          _skBar(width: 80),
          const SizedBox(height: 8),
          _skBar(width: 60, opacity: .25),
          const SizedBox(height: 12),
          _skBar(width: 90, height: 10, opacity: .3),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  final String? url;
  final double size;
  const _CoachAvatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final borderGradient = const LinearGradient(
      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: borderGradient,
        ),
        child: Icon(Icons.person, color: Colors.white, size: size * .52),
      );
    }
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: borderGradient,
        ),
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.white.withOpacity(.08),
            child: Icon(Icons.person, color: Colors.white, size: size * .52),
          ),
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return Container(
              alignment: Alignment.center,
              color: Colors.white.withOpacity(.05),
              child: SizedBox(
                width: size * .4,
                height: size * .4,
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

class _CoachListSkeleton extends StatelessWidget {
  const _CoachListSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1B1D), Color(0xFF232327)],
        ),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.07),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skBar(width: 120),
                const SizedBox(height: 8),
                _skBar(width: 160, height: 10, opacity: .25),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _skBar({double width = 100, double height = 12, double opacity = .15}) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(8),
      ),
    );
