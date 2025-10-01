import 'package:flutter/foundation.dart';

/// Enum for meal type aligning with backend values (case-insensitive mapping)
/// Adjust strings here if backend uses different naming.
enum MealType { breakfast, lunch, dinner, snack, unknown }

MealType mealTypeFromString(String? raw) {
  if (raw == null) return MealType.unknown;
  switch (raw.toLowerCase()) {
    case 'breakfast':
      return MealType.breakfast;
    case 'lunch':
      return MealType.lunch;
    case 'dinner':
      return MealType.dinner;
    case 'snack':
      return MealType.snack;
    default:
      return MealType.unknown;
  }
}

String mealTypeToString(MealType t) {
  switch (t) {
    case MealType.breakfast:
      return 'BREAKFAST';
    case MealType.lunch:
      return 'LUNCH';
    case MealType.dinner:
      return 'DINNER';
    case MealType.snack:
      return 'SNACK';
    case MealType.unknown:
      return 'UNKNOWN';
  }
}

class Meal {
  final String id;
  final String name;
  final int calories; // total calories for this meal entry
  final double? protein; // grams (optional currently)
  final double? carbs; // grams
  final double? fat; // grams
  final MealType type;
  final DateTime eatenAt; // timestamp (when the meal was eaten)

  const Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.type,
    required this.eatenAt,
  });

  Meal copyWith({
    String? id,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    MealType? type,
    DateTime? eatenAt,
  }) => Meal(
    id: id ?? this.id,
    name: name ?? this.name,
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    type: type ?? this.type,
    eatenAt: eatenAt ?? this.eatenAt,
  );

  factory Meal.fromJson(Map<String, dynamic> json) {
    // Backend may nest fields or return macros; we keep optional.
    final eaten = json['eatenAt'] ?? json['createdAt'] ?? json['updatedAt'];
    DateTime eatenAt = DateTime.now();
    if (eaten is String) {
      final parsed = DateTime.tryParse(eaten);
      if (parsed != null) eatenAt = parsed;
    }
    final rawId = json['mealId'] ?? json['id'];
    return Meal(
      id: rawId?.toString() ?? UniqueKey().toString(),
      name: json['name']?.toString() ?? 'Meal',
      calories: (json['calories'] is num)
          ? (json['calories'] as num).round()
          : (json['energy'] is num)
          ? (json['energy'] as num).round()
          : 0,
      protein: json['protein'] is num
          ? (json['protein'] as num).toDouble()
          : null,
      carbs: json['carbs'] is num ? (json['carbs'] as num).toDouble() : null,
      fat: json['fat'] is num ? (json['fat'] as num).toDouble() : null,
      type: mealTypeFromString((json['mealType'] ?? json['type'])?.toString()),
      eatenAt: eatenAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'mealType': mealTypeToString(type),
    'eatenAt': eatenAt.toIso8601String(),
  };
}
