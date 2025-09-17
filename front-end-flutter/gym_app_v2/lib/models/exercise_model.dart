class ExerciseModel {
  final String id;
  final String name;
  final String? userId;
  final String? userName;
  final String? equipmentId;
  final String? description;
  final String? instruction;
  final String? videoUrl;
  final double? met;
  final int? defaultWeight;
  final int? defaultSets;
  final int? defaultReps;
  final int? restTime; // seconds
  final int? defaultTimePerSetSec;
  final List<String> muscleGroupNames;

  ExerciseModel({
    required this.id,
    required this.name,
    this.userId,
    this.userName,
    this.equipmentId,
    this.description,
    this.instruction,
    this.videoUrl,
    this.met,
    this.defaultWeight,
    this.defaultSets,
    this.defaultReps,
    this.restTime,
    this.defaultTimePerSetSec,
    this.muscleGroupNames = const [],
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    final mg = <String>[];
    final mgList = json['muscleGroups'];
    if (mgList is List) {
      for (final item in mgList) {
        if (item is Map) {
          final mgObj = item['muscleGroup'];
          if (mgObj is Map && mgObj['name'] is String) {
            mg.add(mgObj['name'] as String);
          }
        }
      }
    }
    return ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      userId: json['userId'] as String?,
      userName: (json['user'] is Map)
          ? (json['user']['name'] as String?)
          : null,
      equipmentId: json['equipmentId'] as String?,
      description: json['description'] as String?,
      instruction: json['instruction'] as String?,
      videoUrl: json['videoUrl'] as String?,
      met: json['met'] is num ? (json['met'] as num).toDouble() : null,
      defaultWeight: json['defaultWeight'] as int?,
      defaultSets: json['defaultSets'] as int?,
      defaultReps: json['defaultReps'] as int?,
      restTime: json['restTime'] as int?,
      defaultTimePerSetSec: json['defaultTimePerSetSec'] as int?,
      muscleGroupNames: mg,
    );
  }
}
