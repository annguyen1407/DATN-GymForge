import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../services/api_constants.dart';

/// TokenPair model
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime? accessExp; // optional decoded exp
  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.accessExp,
  });
}

/// Detailed refresh status codes for diagnostics / UI.
enum RefreshStatus {
  success,
  noRefreshToken,
  networkError,
  invalidToken, // 401/403
  serverError, // 5xx
  decodeError, // malformed body
  unknownError,
}

class RefreshOutcome {
  final RefreshStatus status;
  final TokenPair? pair;
  final String? message;
  const RefreshOutcome(this.status, {this.pair, this.message});

  bool get ok => status == RefreshStatus.success;
  @override
  String toString() => 'RefreshOutcome(status=$status, message=$message)';
}

/// Centralized TokenManager to avoid duplicate refresh calls.
/// Usage pattern:
///   final token = await TokenManager.instance.getValidAccessToken();
///   // use token in headers
class TokenManager {
  TokenManager._();
  static final TokenManager instance = TokenManager._();

  final _secure = const FlutterSecureStorage();
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> _getAccessToken() async {
    final p = await _prefs;
    return p.getString('access_token');
  }

  Future<String?> _getRefreshToken() async =>
      _secure.read(key: 'refresh_token');

  Future<void> _saveTokens(String access, String refresh) async {
    final p = await _prefs;
    await p.setString('access_token', access);
    await _secure.write(key: 'refresh_token', value: refresh);
  }

  // In-flight refresh future (single-flight)
  Future<TokenPair?>? _inFlight;

  DateTime? _extractExp(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final map = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (map is Map && map['exp'] is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          map['exp'] * 1000,
          isUtc: true,
        ).toLocal();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isExpired(String? token) {
    if (token == null) return true;
    final exp = _extractExp(token);
    if (exp == null) return false; // cannot parse -> assume valid
    // Refresh when < 60s remaining
    return DateTime.now().isAfter(exp.subtract(const Duration(seconds: 60)));
  }

  /// Public: ensure we have a fresh access token.
  Future<String?> getValidAccessToken() async {
    final access = await _getAccessToken();
    if (!_isExpired(access)) return access;

    // If a refresh already running, await it
    if (_inFlight != null) {
      final pair = await _inFlight;
      return pair?.accessToken;
    }

    final refresh = await _getRefreshToken();
    if (refresh == null) return null;

    final completer = Completer<TokenPair?>();
    _inFlight = completer.future;
    try {
      final pair = await _doRefresh(refresh);
      completer.complete(pair);
      return pair?.accessToken;
    } catch (e) {
      completer.complete(null);
      return null;
    } finally {
      _inFlight = null;
    }
  }

  /// Decode current access token payload (claims). Returns null if none/invalid.
  Future<Map<String, dynamic>?> getAccessTokenClaims() async {
    final token = await _getAccessToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Convenience: extract current user id (sub) from access token.
  Future<String?> getCurrentUserId() async {
    final claims = await getAccessTokenClaims();
    if (claims == null) return null;
    final sub = claims['sub'];
    if (sub is String && sub.isNotEmpty) return sub;
    return null;
  }

  Future<TokenPair?> _doRefresh(String refreshToken) async {
    final outcome = await forceRefresh(refreshToken: refreshToken);
    return outcome.pair; // backward compatibility (null if not success)
  }

  /// Public explicit refresh with detailed outcome.
  /// You can call this to proactively renew before a critical operation.
  Future<RefreshOutcome> forceRefresh({String? refreshToken}) async {
    try {
      final token = refreshToken ?? await _getRefreshToken();
      if (token == null) {
        return const RefreshOutcome(RefreshStatus.noRefreshToken);
      }
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/refresh');
      final res = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': token}),
      );
      if (res.statusCode == 401 || res.statusCode == 403) {
        return const RefreshOutcome(RefreshStatus.invalidToken);
      }
      if (res.statusCode >= 500) {
        return RefreshOutcome(
          RefreshStatus.serverError,
          message: 'Server error ${res.statusCode}',
        );
      }
      if (res.statusCode != 200) {
        return RefreshOutcome(
          RefreshStatus.unknownError,
          message: 'Unexpected status ${res.statusCode}',
        );
      }
      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        return const RefreshOutcome(RefreshStatus.decodeError);
      }
      final newAccess = body['access_token'] as String?;
      final newRefresh = body['refresh_token'] as String?;
      if (newAccess == null || newRefresh == null) {
        return const RefreshOutcome(RefreshStatus.decodeError);
      }
      await _saveTokens(newAccess, newRefresh);
      final pair = TokenPair(
        accessToken: newAccess,
        refreshToken: newRefresh,
        accessExp: _extractExp(newAccess),
      );
      return RefreshOutcome(RefreshStatus.success, pair: pair);
    } on http.ClientException catch (e) {
      return RefreshOutcome(RefreshStatus.networkError, message: e.toString());
    } on TimeoutException catch (e) {
      return RefreshOutcome(RefreshStatus.networkError, message: 'Timeout: $e');
    } catch (e) {
      return RefreshOutcome(RefreshStatus.unknownError, message: e.toString());
    }
  }

  /// Wrapper helper to perform authorized GET with auto-refresh & single retry
  Future<http.Response?> authorizedGet(String path) async {
    final token = await getValidAccessToken();
    if (token == null) return null;
    final url = Uri.parse('${ApiConstants.baseUrl}$path');
    var res = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) {
      // Try one refresh explicit (maybe token just rotated elsewhere)
      final retryToken = await getValidAccessToken();
      if (retryToken == null) return res; // let caller decide logout
      res = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $retryToken',
        },
      );
    }
    return res;
  }
}
