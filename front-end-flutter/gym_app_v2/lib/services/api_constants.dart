import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API constants loaded from environment (.env)
class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    final v = dotenv.env['API_BASE_URL'];
    if (v == null || v.isEmpty) {
      // Fallback để tránh crash nếu quên load .env
      return 'http://localhost:3000';
    }
    // Remove trailing slashes if any (simple manual trim to avoid regex issues)
    String cleaned = v.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}
