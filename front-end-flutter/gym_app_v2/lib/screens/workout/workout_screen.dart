import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/pill_tab_bar.dart';
import 'explore_tab.dart';
import 'plan_tab.dart';
import 'expert_tab.dart';
import '../../widgets/animations/animated_appear.dart';

/// WorkoutScreen: Tab "Workout" hiển thị các nhóm workout, tab, search, category icon
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
    _controller.addListener(() {
      if (mounted) setState(() {}); // rebuild to update isActive flag
    });
  }

  @override
  void dispose() {
    _controller.removeListener(() {}); // safe cleanup (listener inline no-op)
    _controller.dispose();
    super.dispose();
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
          bottom: PillTabBar(
            controller: _controller,
            labels: const ['Khám phá', 'Kế hoạch', 'Chuyên gia'],
            // Match previous look: slightly larger font
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            indicatorOpacity: 0.22,
            height: kTextTabBarHeight + 20,
            horizontalPadding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          ),
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
                    child: const ExpertTab(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
