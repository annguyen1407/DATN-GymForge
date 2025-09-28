import '../core/api/api_client.dart';
import '../core/logging/app_logger.dart';
import '../models/meal_model.dart';

/// Repository for CRUD operations limited to list/add/delete for meals.
class MealsRepository {
  MealsRepository();

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<List<Meal>> getMealsForDay({required DateTime date}) async {
    final dateStr = _fmt(date);
    // Backend: GET /meals/my/:date
    final path = '/meals/my/$dateStr';
    try {
      final res = await ApiClient.instance.requestJson('GET', path);
      if (res.status != 200) {
        AppLogger.warn(
          'Meals list failed status ${res.status}',
          tag: 'MealsRepo',
        );
        return const [];
      }
      final raw = res.data;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(Meal.fromJson)
            .toList(growable: false);
      }
      return const [];
    } catch (e, st) {
      AppLogger.error(
        'Meals list error $e',
        tag: 'MealsRepo',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<Meal?> addMeal({
    required DateTime date,
    required String name,
    required int calories,
    required MealType type,
  }) async {
    final dateStr = _fmt(date);
    // Backend expects DTO AddMealForDayDto: { name, calories, type }
    final body = {
      'name': name,
      'calories': calories,
      'type': mealTypeToString(type),
    };
    try {
      final res = await ApiClient.instance.requestJson(
        'POST',
        '/meals/day/my/$dateStr',
        body: body,
      );
      if (res.status >= 200 &&
          res.status < 300 &&
          res.data is Map<String, dynamic>) {
        return Meal.fromJson(res.data as Map<String, dynamic>);
      }
      AppLogger.warn('Add meal failed status ${res.status}', tag: 'MealsRepo');
      return null;
    } catch (e, st) {
      AppLogger.error(
        'Add meal error $e',
        tag: 'MealsRepo',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<bool> deleteMeal({
    required DateTime date,
    required String mealId,
  }) async {
    try {
      final dateStr = _fmt(date);
      final res = await ApiClient.instance.requestJson(
        'DELETE',
        '/meals/day/my/$dateStr/$mealId',
      );
      if (res.status >= 200 && res.status < 300) return true;
      AppLogger.warn(
        'Delete meal failed status ${res.status}',
        tag: 'MealsRepo',
      );
      return false;
    } catch (e, st) {
      AppLogger.error(
        'Delete meal error $e',
        tag: 'MealsRepo',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
