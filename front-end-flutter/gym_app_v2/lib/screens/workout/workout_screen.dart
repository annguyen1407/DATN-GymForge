import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/workout_tab_bar.dart';
import 'explore_tab.dart';
import 'plan_tab.dart';
import 'expert_tab.dart';

/// WorkoutScreen: Tab "Workout" hiển thị các nhóm workout, tab, search, category icon
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              WorkoutTabBar(
                selectedTab: selectedTab,
                onTabSelected: (index) => setState(() => selectedTab = index),
              ),
              Expanded(
                child: IndexedStack(
                  index: selectedTab,
                  children: const [ExploreTab(), PlanTab(), ExpertTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
