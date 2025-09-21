import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/pill_tab_bar.dart';
import 'explore_tab.dart';
import 'plan_tab.dart';
import 'expert_tab.dart';

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
          child: TabBarView(
            controller: _controller,
            children: [
              const ExploreTab(),
              // Keep isActive behavior: compare current index
              Builder(
                builder: (context) => PlanTab(
                  key: ValueKey('PlanTab-${_controller.index}'),
                  isActive: _controller.index == 1,
                ),
              ),
              const ExpertTab(),
            ],
          ),
        ),
      ),
    );
  }
}
