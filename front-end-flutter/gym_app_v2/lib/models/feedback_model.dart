class FeedbackUserModel {
  final String id;
  final String? name;
  final String? email;
  const FeedbackUserModel({required this.id, this.name, this.email});
  factory FeedbackUserModel.fromJson(Map<String, dynamic> json) =>
      FeedbackUserModel(
        id: json['id'] ?? '',
        name: json['name'],
        email: json['email'],
      );
}

class FeedbackGymerModel {
  final String id;
  final String userId;
  final FeedbackUserModel? user;
  const FeedbackGymerModel({required this.id, required this.userId, this.user});
  factory FeedbackGymerModel.fromJson(Map<String, dynamic> json) =>
      FeedbackGymerModel(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        user: json['user'] is Map<String, dynamic>
            ? FeedbackUserModel.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );
}

class FeedbackCoachModel {
  final String id;
  final String userId;
  final FeedbackUserModel? user;
  const FeedbackCoachModel({required this.id, required this.userId, this.user});
  factory FeedbackCoachModel.fromJson(Map<String, dynamic> json) =>
      FeedbackCoachModel(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        user: json['user'] is Map<String, dynamic>
            ? FeedbackUserModel.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );
}

class FeedbackModel {
  final String id;
  final String gymerId;
  final String coachId;
  final int rating; // assume 1..5
  final String? content;
  final DateTime createdAt;
  final FeedbackGymerModel? gymer;
  final FeedbackCoachModel? coach;

  FeedbackModel({
    required this.id,
    required this.gymerId,
    required this.coachId,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.gymer,
    this.coach,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? '',
      gymerId: json['gymerId'] ?? '',
      coachId: json['coachId'] ?? '',
      rating: (json['rating'] is num) ? (json['rating'] as num).toInt() : 0,
      content: json['content'],
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      gymer: json['gymer'] is Map<String, dynamic>
          ? FeedbackGymerModel.fromJson(json['gymer'] as Map<String, dynamic>)
          : null,
      coach: json['coach'] is Map<String, dynamic>
          ? FeedbackCoachModel.fromJson(json['coach'] as Map<String, dynamic>)
          : null,
    );
  }
}
