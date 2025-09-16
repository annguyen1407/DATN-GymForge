import 'api_response.dart';

typedef JsonMap = Map<String, dynamic>;

/// Generic safe model parsing utilities for ApiResponse.
class ApiMapper {
  /// Parse a single object response into a model.
  static T? mapObject<T>(ApiResponse resp, T Function(JsonMap json) fromJson) {
    if (!resp.ok) return null;
    if (resp.raw is! JsonMap) return null;
    try {
      return fromJson(resp.raw as JsonMap);
    } catch (_) {
      return null;
    }
  }

  /// Parse a list response into list of model.
  static List<T> mapList<T>(
    ApiResponse resp,
    T Function(JsonMap json) fromJson,
  ) {
    if (!resp.ok) return const [];
    if (resp.raw is! List) return const [];
    final list = resp.raw as List;
    return list
        .whereType<JsonMap>()
        .map((e) {
          try {
            return fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }
}

/// Extensions for more fluent usage.
extension ApiResponseParsing on ApiResponse {
  T? asModel<T>(T Function(JsonMap json) fromJson) =>
      ApiMapper.mapObject(this, fromJson);
  List<T> asModelList<T>(T Function(JsonMap json) fromJson) =>
      ApiMapper.mapList(this, fromJson);
}
