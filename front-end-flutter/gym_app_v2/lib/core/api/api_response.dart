/// Unified API response wrapper
/// Provides a typed structure to interpret HTTP responses consistently.
class ApiResponse<T> {
  final int status;
  final T? data; // parsed body (JSON map/list or custom)
  final dynamic raw; // original decoded JSON (Map/List/primitive) if needed
  final ApiErrorType? error;
  final String? message; // optional server / local message

  bool get ok => status >= 200 && status < 300 && error == null;

  ApiResponse({
    required this.status,
    this.data,
    this.raw,
    this.error,
    this.message,
  });

  @override
  String toString() =>
      'ApiResponse(status=$status, ok=$ok, error=$error, message=$message)';
}

enum ApiErrorType {
  unauthorized,
  network,
  timeout,
  decode,
  server,
  client,
  unknown,
}
