import 'package:flutter/material.dart';

// Lightweight model-like maps kept for now; API integration can replace.
class NutritionTab extends StatefulWidget {
  final List<Map<String, dynamic>>
  meals; // each: {meal: String, foods: [{name, calories}]}
  final int totalIntake; // tổng calo nạp
  final int totalBurned; // tổng calo đốt
  final void Function(Map<String, dynamic> meal) onAddFood;
  final void Function(Map<String, dynamic> meal, int index) onRemoveFood;

  const NutritionTab({
    super.key,
    required this.meals,
    required this.totalIntake,
    required this.totalBurned,
    required this.onAddFood,
    required this.onRemoveFood,
  });

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  late Map<String, bool> _expanded; // meal name -> expanded?

  @override
  void initState() {
    super.initState();
    _expanded = {for (final m in widget.meals) (m['meal'] as String): true};
  }

  @override
  void didUpdateWidget(covariant NutritionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Preserve existing expansion states, default new meals to expanded
    for (final m in widget.meals) {
      final key = m['meal'] as String;
      _expanded.putIfAbsent(key, () => true);
    }
    // Remove states of meals no longer present
    _expanded.removeWhere((k, v) => !widget.meals.any((m) => m['meal'] == k));
  }

  int _mealCalories(List<Map<String, dynamic>> foods) =>
      foods.fold<int>(0, (s, f) => s + (f['calories'] as int));

  double _burnedRatio() {
    if (widget.totalIntake <= 0) return 0;
    return (widget.totalBurned / widget.totalIntake).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final hasAny = widget.meals.any((m) => (m['foods'] as List).isNotEmpty);
    final burnedRatio = _burnedRatio();
    final remaining = widget.totalIntake - widget.totalBurned;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EnergyOverview(
            totalIntake: widget.totalIntake,
            totalBurned: widget.totalBurned,
            burnedRatio: burnedRatio,
            remaining: remaining < 0 ? 0 : remaining,
          ),
          const SizedBox(height: 28),
          ...widget.meals.map((meal) {
            final foods = (meal['foods'] as List<Map<String, dynamic>>);
            final cals = _mealCalories(foods);
            final mealName = meal['meal'] as String? ?? '';
            final isOpen = _expanded[mealName] ?? true;
            return _MealCard(
              meal: meal,
              calories: cals,
              expanded: isOpen,
              onToggle: () => setState(() {
                _expanded[mealName] = !(isOpen);
              }),
              onAdd: () => widget.onAddFood(meal),
              onRemove: (idx) => widget.onRemoveFood(meal, idx),
            );
          }),
          if (!hasAny) ...[
            const SizedBox(height: 30),
            Center(
              child: Text(
                'Chưa có bữa ăn nào được ghi lại',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  letterSpacing: .2,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal; // { meal: String, foods: List<Map> }
  final int calories;
  final bool expanded;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final VoidCallback onToggle;

  const _MealCard({
    required this.meal,
    required this.calories,
    required this.expanded,
    required this.onAdd,
    required this.onRemove,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final foods = (meal['foods'] as List<Map<String, dynamic>>);
    return AnimatedContainer(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[850]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meal['meal'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: .2,
                  ),
                ),
              ),
              _MealKcalBadge(kcal: calories),
              const SizedBox(width: 10),
              _AddButton(onTap: onAdd),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedRotation(
                  turns: expanded ? 0.0 : -0.25,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: expanded
                ? const SizedBox(height: 12)
                : const SizedBox.shrink(),
          ),
          if (expanded && foods.isEmpty)
            Text(
              'Chưa có món nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
            )
          else if (expanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, i) {
                final f = foods[i];
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 8,
                      ), // indent relative to meal header
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: .15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${f['calories']} kcal',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                letterSpacing: .2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RemoveButton(onTap: () => onRemove(i)),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => Divider(
                height: 16,
                thickness: .7,
                indent: 14,
                endIndent: 4,
                color: Colors.grey[850],
              ),
              itemCount: foods.length,
            ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF8854FF), width: 1.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.add, size: 14, color: Color(0xFF8854FF)),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent, width: 1.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.close, size: 13, color: Colors.redAccent),
      ),
    );
  }
}

// Compact energy overview widget
class _EnergyOverview extends StatelessWidget {
  final int totalIntake;
  final int totalBurned;
  final double burnedRatio; // 0..1
  final int remaining;
  const _EnergyOverview({
    required this.totalIntake,
    required this.totalBurned,
    required this.burnedRatio,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[850]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Năng lượng hôm nay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
              const Spacer(),
              _BurnBadge(percent: burnedRatio),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              LayoutBuilder(
                builder: (ctx, c) => AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  height: 18,
                  width: c.maxWidth * burnedRatio,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A48), Color(0xFFE3A63B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Nạp vào',
                  '$totalIntake Cal',
                  Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _miniStat(
                  'Đã đốt',
                  '$totalBurned Cal',
                  const Color(0xFFFF6A48),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _miniStat(
                  'Còn lại',
                  '$remaining Cal',
                  Colors.lightGreenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BurnBadge extends StatelessWidget {
  final double percent; // 0..1
  const _BurnBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0, 1.0);
    final display = (p * 100).round();

    // Color/gradient tiers
    LinearGradient gradient;
    Color textColor = Colors.white;
    if (p < 0.40) {
      gradient = const LinearGradient(
        colors: [Color(0xFF4D7CFE), Color(0xFF3AD4D8)],
      );
    } else if (p < 0.70) {
      gradient = const LinearGradient(
        colors: [Color(0xFFFF9F43), Color(0xFFFF784A)],
      );
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFFFF5E3A), Color(0xFFFF9500)],
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$display% đốt',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealKcalBadge extends StatelessWidget {
  final int kcal;
  const _MealKcalBadge({required this.kcal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8854FF).withAlpha(46), // ~18%
            const Color(0xFFB07CFF).withAlpha(46),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF8854FF).withAlpha(140), // ~55%
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_dining, size: 15, color: Color(0xFFB892FF)),
          const SizedBox(width: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB892FF),
                    letterSpacing: .2,
                  ),
                ),
                const TextSpan(
                  text: ' kcal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE2D4FF),
                    letterSpacing: .1,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
