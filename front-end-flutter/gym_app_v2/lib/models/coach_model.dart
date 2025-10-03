class CoachUserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? profilePicture;
  final String? biography;

  CoachUserModel({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.profilePicture,
    this.biography,
  });

  factory CoachUserModel.fromJson(Map<String, dynamic> json) => CoachUserModel(
    id: json['id'] ?? '',
    name: json['name'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    profilePicture: json['profilePicture'],
    biography: json['biography'],
  );
}

class CoachModel {
  final String id;
  final String userId;
  final String? certification;
  final String status;
  final double? averageRating;
  final int feedbackCount;
  final bool isOpenToTraining;
  final double? trainingPrice;
  final List<String> expertises;
  final CoachUserModel? user;
  final int appointmentsCount;
  final int feedbacksCount;
  final int trainingRequestsSentCount;

  CoachModel({
    required this.id,
    required this.userId,
    this.certification,
    required this.status,
    this.averageRating,
    required this.feedbackCount,
    required this.isOpenToTraining,
    this.trainingPrice,
    required this.expertises,
    this.user,
    required this.appointmentsCount,
    required this.feedbacksCount,
    required this.trainingRequestsSentCount,
  });

  factory CoachModel.fromJson(Map<String, dynamic> json) {
    return CoachModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      certification: json['certification'],
      status: json['status'] ?? 'UNKNOWN',
      averageRating: (json['averageRating'] is num)
          ? (json['averageRating'] as num).toDouble()
          : null,
      feedbackCount: (json['feedbackCount'] ?? 0) as int,
      isOpenToTraining: json['isOpenToTraining'] == true,
      trainingPrice: (json['trainingPrice'] is num)
          ? (json['trainingPrice'] as num).toDouble()
          : null,
      expertises: (json['expertises'] is List)
          ? (json['expertises'] as List).whereType<String>().toList()
          : const <String>[],
      user: json['user'] is Map<String, dynamic>
          ? CoachUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      appointmentsCount:
          json['_count'] is Map && (json['_count']['appointments'] is int)
          ? json['_count']['appointments'] as int
          : 0,
      feedbacksCount:
          json['_count'] is Map && (json['_count']['feedbacks'] is int)
          ? json['_count']['feedbacks'] as int
          : 0,
      trainingRequestsSentCount:
          json['_count'] is Map &&
              (json['_count']['trainingRequestsSent'] is int)
          ? json['_count']['trainingRequestsSent'] as int
          : 0,
    );
  }
}
