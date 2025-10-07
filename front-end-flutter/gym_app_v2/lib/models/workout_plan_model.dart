import '../core/api/api_mapper.dart';

class WorkoutPlanModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? picture;
  final String planType; // e.g., STRENGTH
  final String status; // e.g., ACTIVE
  final int days;
  final bool isTemplate;
  // Whether this template is only available to premium users.
  // Backend field expected: isPremiumOnly (optional). Defaults to false when absent.
  final bool isPremiumOnly;
  final int exercisesCount;
  final String? userName;
  final String? userEmail;
  // Link to a coach-gymer training request (nullable if plan not tied to a contract)
  final String? trainingRequestId;

  WorkoutPlanModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.picture,
    required this.planType,
    required this.status,
    required this.days,
    required this.isTemplate,
    required this.isPremiumOnly,
    required this.exercisesCount,
    this.userName,
    this.userEmail,
    this.trainingRequestId,
  });

  factory WorkoutPlanModel.fromJson(JsonMap json) {
    final count = json['_count'];
    final user = json['user'];
    return WorkoutPlanModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      picture: json['picture'] as String?,
      planType: json['planType'] as String? ?? 'UNKNOWN',
      status: json['status'] as String? ?? 'UNKNOWN',
      days: (json['days'] is int) ? json['days'] as int : 0,
      isTemplate: json['isTemplate'] as bool? ?? false,
      isPremiumOnly: json['isPremiumOnly'] as bool? ?? false,
      exercisesCount: count is Map && count['exercises'] is int
          ? count['exercises'] as int
          : 0,
      userName: user is Map ? user['name'] as String? : null,
      userEmail: user is Map ? user['email'] as String? : null,
      trainingRequestId: json['trainingRequestId'] as String?,
    );
  }
}
