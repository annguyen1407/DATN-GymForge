import 'package:flutter/material.dart';
import '../../../widgets/log_plan_card.dart';
import '../../../widgets/plan_type_badge.dart';

class PlansTab extends StatelessWidget {
  final List<Map<String, dynamic>> plans;
  final Color Function(String?) planTypeColor;
  final Widget Function(dynamic) dayBadgeBuilder;
  final void Function(Map<String, dynamic>) onOpenPlan;
  const PlansTab({
    super.key,
    required this.plans,
    required this.planTypeColor,
    required this.dayBadgeBuilder,
    required this.onOpenPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: plans.isEmpty
          ? const Center(
              child: Text(
                'No plans available',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.separated(
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final plan = plans[i];
                final type = plan['planType']?.toString();
                return PlanCard(
                  plan: plan,
                  planTypeColor: planTypeColor(type),
                  dayBadge: dayBadgeBuilder(plan['dayNumber']),
                  planTypeChip: type == null
                      ? const SizedBox.shrink()
                      : PlanTypeBadge(
                          planType: type.toUpperCase(),
                          dense: true,
                          fontSize: 11,
                        ),
                  onTap: () => onOpenPlan(plan),
                );
              },
            ),
    );
  }
}
