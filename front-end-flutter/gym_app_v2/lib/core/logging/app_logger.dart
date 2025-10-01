import 'package:flutter/foundation.dart';

/// Centralized logging utility to replace raw print calls.
/// Provides consistent tagging, easy future redirection (e.g., to Sentry),
/// and avoids avoid_print lint by using debugPrint.
class AppLogger {
  AppLogger._();

  static const String _defaultTag = 'APP';

  static void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }

  static void warn(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('WARN', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final ts = DateTime.now().toIso8601String();
    final b = StringBuffer()
      ..write('[$ts][$level][${tag ?? _defaultTag}] ')
      ..write(message);
    if (error != null) {
      b.write(' | error: $error');
    }
    if (stackTrace != null) {
      b.write('\n$stackTrace');
    }
    // debugPrint throttles long output safely versus print.
    debugPrint(b.toString());
  }
}
