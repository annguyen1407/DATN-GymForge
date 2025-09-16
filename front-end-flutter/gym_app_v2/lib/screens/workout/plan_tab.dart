import 'package:flutter/material.dart';
import '../../repositories/workout_plans_repository.dart';
import '../../models/workout_plan_model.dart';
import '../../widgets/workout_card.dart';
import 'workout_detail_screen.dart';
import 'create_workout_plan_screen.dart';

class PlanTab extends StatefulWidget {
  final bool isActive; // parent passes whether this tab is currently visible
  const PlanTab({super.key, this.isActive = false});

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> {
  final _repo = WorkoutPlansRepository();
  Future<List<WorkoutPlanModel>>?
  _future; // nullable to avoid LateInitializationError

  // TODO: Lấy userId động từ profile (hiện tạm hardcode hoặc inject)
  static const _placeholderUserId = '489e6bb3-2732-4bc1-bd66-0556e9a1f8b1';

  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _triggerFetch();
    }
  }

  @override
  void didUpdateWidget(covariant PlanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _triggerFetch(force: _initialLoaded);
    }
  }

  void _triggerFetch({bool force = false}) {
    if (_initialLoaded && !force) return;
    setState(() {
      _future = _repo.getPlans(userId: _placeholderUserId);
      _initialLoaded = true;
    });
  }

  Future<void> _pullToRefresh() async {
    _triggerFetch(force: true);
    final fut = _future;
    if (fut != null) {
      await fut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<WorkoutPlanModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (_future == null) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => _triggerFetch(force: true),
                  child: const Text('Tải kế hoạch'),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Lỗi tải kế hoạch',
                onRetry: () {
                  _triggerFetch(force: true);
                },
              );
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return _EmptyState(onRefresh: () => _triggerFetch(force: true));
            }
            return RefreshIndicator(
              onRefresh: _pullToRefresh,
              color: Colors.redAccent,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final plan = data[index];
                  final subtitleParts = <String>[];
                  // Giả định model có thể nullable; nếu thực tế non-null có thể bỏ if để đơn giản hoá
                  subtitleParts.add('${plan.days} ngày');
                  subtitleParts.add('${plan.exercisesCount} bài tập');
                  final subtitle = subtitleParts.join(' • ');
                  return WorkoutCard(
                    image: plan.picture ?? '',
                    title: plan.name,
                    subtitle: subtitle.isEmpty ? null : subtitle,
                    description: plan.description,
                    badge: plan.planType,
                    planType: plan.planType,
                    tags: [
                      if (plan.userName != null) 'Bởi: ${plan.userName}',
                      plan.status,
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutDetailScreen(
                            image: plan.picture ?? '',
                            title: plan.name,
                            subtitle: plan.userName ?? 'Coach',
                            description: plan.description ?? 'Không có mô tả',
                            exercises: const [],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateWorkoutPlanScreen(userId: _placeholderUserId),
                ),
              );
              if (created != null) {
                _triggerFetch(force: true);
              }
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 56, color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            'Chưa có kế hoạch nào',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRefresh, child: const Text('Tải lại')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
