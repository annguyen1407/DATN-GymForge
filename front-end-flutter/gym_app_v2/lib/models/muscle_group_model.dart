class MuscleGroupModel {
  final String id;
  final String name;
  final int exercisesCount;

  MuscleGroupModel({
    required this.id,
    required this.name,
    required this.exercisesCount,
  });

  factory MuscleGroupModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'];
    int exercises = 0;
    if (count is Map && count['exercises'] is int) {
      exercises = count['exercises'] as int;
    }
    return MuscleGroupModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      exercisesCount: exercises,
    );
  }
}
