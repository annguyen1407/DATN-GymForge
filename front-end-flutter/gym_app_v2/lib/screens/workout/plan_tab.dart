import 'package:flutter/material.dart';
import 'dart:convert';
import '../../widgets/add_action_button.dart';
import '../../widgets/app_button.dart';
import '../../repositories/workout_plans_repository.dart';
import '../../core/auth/token_manager.dart';
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

  String? _userId; // sẽ decode từ JWT

  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initAndFetch();
    }
  }

  @override
  void didUpdateWidget(covariant PlanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _initAndFetch(force: _initialLoaded);
    }
  }

  Future<void> _initAndFetch({bool force = false}) async {
    if (_initialLoaded && !force) return;
    // Decode userId (sub) từ access token hiện tại
    final token = await TokenManager.instance.getValidAccessToken();
    String? userId;
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(
            base64Url.decode(base64Url.normalize(parts[1])),
          );
          final map = jsonDecode(payload);
          if (map is Map && map['sub'] is String) {
            userId = map['sub'] as String;
          }
        }
      } catch (_) {}
    }
    // Nếu không lấy được, giữ nguyên future = null để hiển thị nút tải lại.
    if (!mounted) return;
    if (userId == null) {
      setState(() {
        _userId = null; // explicit for clarity
        _future = null; // require user to retry (hoặc show login?)
        _initialLoaded = true;
      });
      return;
    }
    setState(() {
      _userId = userId;
      _future = _repo.getPlansByUser(userId!);
      _initialLoaded = true;
    });
  }

  Future<void> _pullToRefresh() async {
    _initAndFetch(force: true);
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
                child: SizedBox(
                  width: 200,
                  child: AppButton.primary(
                    label: 'Tải kế hoạch',
                    onPressed: () => _initAndFetch(force: true),
                    size: AppButtonSize.medium,
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Lỗi tải kế hoạch',
                onRetry: () => _initAndFetch(force: true),
              );
            }
            final rawData = snapshot.data ?? [];
            // Lọc bỏ các plan là template
            final data = rawData.where((p) => !p.isTemplate).toList();
            if (data.isEmpty) {
              return _EmptyState(onRefresh: () => _initAndFetch(force: true));
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
                            planId: plan.id,
                            image: plan.picture ?? '',
                            title: plan.name,
                            subtitle: plan.userName, // bỏ fallback 'Coach'
                            description: plan.description ?? 'Không có mô tả',
                          ),
                        ),
                      ).then((result) {
                        if (result is Map && result['deleted'] == true) {
                          _initAndFetch(force: true);
                        }
                      });
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
          child: AddActionButton.circle(
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateWorkoutPlanScreen(userId: _userId ?? 'unknown'),
                ),
              );
              if (created != null) {
                _initAndFetch(force: true);
              }
            },
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
          AppButton.outline(
            label: 'Tải lại',
            onPressed: onRefresh,
            fullWidth: false,
            size: AppButtonSize.small,
          ),
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
          AppButton.primary(
            label: 'Thử lại',
            onPressed: onRetry,
            fullWidth: false,
            size: AppButtonSize.small,
          ),
        ],
      ),
    );
  }
}
