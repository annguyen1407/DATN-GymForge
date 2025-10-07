import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/pill_tab_bar.dart';
import 'explore_tab.dart';
import 'plan_tab.dart';
import 'expert_tab.dart';
import '../../widgets/animations/animated_appear.dart';
import '../../repositories/current_user_repository.dart';

/// WorkoutScreen: Tab "Workout" hiển thị các nhóm workout, tab, search, category icon
class WorkoutScreen extends StatefulWidget {
  final int initialTabIndex; // 0: Khám phá, 1: Kế hoạch, 2: Chuyên gia
  const WorkoutScreen({super.key, this.initialTabIndex = 0});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  final _currentUserRepo = CurrentUserRepository();
  String? _role; // COACH | GYMER | ADMIN
  bool _loadingRole = false;
  int _lastAllowedIndex =
      0; // lưu tab cuối cùng hợp lệ (không phải expert khi bị disable)
  bool _reverting = false; // cờ tránh loop khi ép quay lại

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _controller.addListener(_handleTabChange);
    _loadRole();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted) return;
    final disabledExpert = _role != null && _role != 'GYMER';
    final idx = _controller.index;
    if (disabledExpert && idx == 2 && !_reverting) {
      // Không cho vào tab chuyên gia -> revert
      _reverting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.animateTo(_lastAllowedIndex);
        }
      });
    } else if (idx != 2) {
      _lastAllowedIndex = idx;
    }
    if (_reverting) {
      Future.delayed(const Duration(milliseconds: 240), () {
        if (mounted) _reverting = false;
      });
    }
    setState(() {}); // cập nhật isActive
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 0, // no visible toolbar, only the tab bar
          bottom: _buildTabBar(),
        ),
        body: SafeArea(
          top: false,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return TabBarView(
                controller: _controller,
                children: [
                  _AnimatedTabWrapper(
                    index: 0,
                    controller: _controller,
                    child: const ExploreTab(),
                  ),
                  Builder(
                    builder: (context) => _AnimatedTabWrapper(
                      index: 1,
                      controller: _controller,
                      child: PlanTab(
                        key: ValueKey('PlanTab-${_controller.index}'),
                        isActive: _controller.index == 1,
                      ),
                    ),
                  ),
                  _AnimatedTabWrapper(
                    index: 2,
                    controller: _controller,
                    child: IgnorePointer(
                      ignoring: _role != null && _role != 'GYMER',
                      child: Opacity(
                        opacity: _role != null && _role != 'GYMER' ? 0.35 : 1,
                        child: ExpertTab(
                          key: ValueKey(
                            'ExpertTab-${_controller.index}-${_role ?? 'unknown'}',
                          ),
                          isActive:
                              _controller.index == 2 &&
                              (_role == null || _role == 'GYMER'),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    final disabled = _role != null && _role != 'GYMER';
    // Sử dụng labels chuẩn của PillTabBar để giữ nguyên kích thước pill tím như cũ
    // Sau đó overlay chặn tab Expert.
    final tabBar = PillTabBar(
      controller: _controller,
      labels: const ['Khám phá', 'Kế hoạch', 'Chuyên gia'],
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      indicatorOpacity: 0.22,
      height: kTextTabBarHeight + 20,
      horizontalPadding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    );

    if (!disabled) return tabBar;

    // Khi disable: dùng LayoutBuilder để tính width mỗi tab và đặt Positioned trực tiếp (tránh ParentDataWidget lỗi)
    return PreferredSize(
      preferredSize: tabBar.preferredSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final each = w / 3;
          return Stack(
            children: [
              tabBar,
              Positioned(
                left: each * 2,
                top: 0,
                width: each,
                height: tabBar.preferredSize.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger?.hideCurrentSnackBar();
                    messenger?.showSnackBar(
                      const SnackBar(
                        content: Text('Tab Chuyên gia chỉ dành cho Gymer'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadRole() async {
    if (_loadingRole) return;
    setState(() => _loadingRole = true);
    try {
      final profile = await _currentUserRepo.fetchProfile();
      if (!mounted) return;
      setState(() => _role = profile?.role);
    } catch (_) {
      // ignore errors; keep role null (treated as gymer until known)
    } finally {
      if (mounted) setState(() => _loadingRole = false);
    }
  }
}

class _AnimatedTabWrapper extends StatefulWidget {
  final int index;
  final TabController controller;
  final Widget child;
  const _AnimatedTabWrapper({
    required this.index,
    required this.controller,
    required this.child,
  });

  @override
  State<_AnimatedTabWrapper> createState() => _AnimatedTabWrapperState();
}

class _AnimatedTabWrapperState extends State<_AnimatedTabWrapper> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.index == widget.index) {
      // show initial tab after first frame for smooth appear
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visible = true);
      });
    }
    widget.controller.addListener(_tabListener);
  }

  void _tabListener() {
    if (widget.controller.index == widget.index && !_visible) {
      setState(() => _visible = true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_tabListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _visible
          ? AnimatedAppear(
              key: ValueKey('tab-${widget.index}-appear'),
              delay: const Duration(milliseconds: 40),
              child: widget.child,
            )
          : const SizedBox.shrink(),
    );
  }
}
