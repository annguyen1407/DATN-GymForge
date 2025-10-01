import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../auth/token_manager.dart';
import '../../services/api_constants.dart';
import 'api_response.dart';

/// Simple unified API client with auto-attach token & 401 single retry.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<http.Response?> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _authorizedRequest('GET', path, headers: headers);
  }

  Future<http.Response?> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _authorizedRequest('POST', path, headers: headers, body: body);
  }

  Future<http.Response?> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _authorizedRequest('PATCH', path, headers: headers, body: body);
  }

  Future<http.Response?> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _authorizedRequest('PUT', path, headers: headers, body: body);
  }

  Future<http.Response?> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _authorizedRequest('DELETE', path, headers: headers, body: body);
  }

  /// High-level JSON request returning ApiResponse wrapper.
  /// If T is provided, caller can map manually afterwards; for now we keep T dynamic.
  Future<ApiResponse<dynamic>> requestJson(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final res = await _authorizedRequest(
        method,
        path,
        headers: headers,
        body: body,
      );
      if (res == null) {
        return ApiResponse(
          status: 0,
          error: ApiErrorType.unauthorized,
          message: 'No token / unauthorized',
        );
      }
      dynamic decoded;
      if (res.body.isNotEmpty) {
        try {
          decoded = jsonDecode(res.body);
        } catch (_) {
          return ApiResponse(
            status: res.statusCode,
            error: ApiErrorType.decode,
            message: 'Failed to decode JSON',
          );
        }
      }
      final status = res.statusCode;
      if (status >= 200 && status < 300) {
        return ApiResponse(status: status, raw: decoded, data: decoded);
      }
      return ApiResponse(
        status: status,
        raw: decoded,
        error: _mapStatusToError(status),
        message: decoded is Map && decoded['message'] is String
            ? decoded['message']
            : null,
      );
    } on SocketException {
      return ApiResponse(
        status: 0,
        error: ApiErrorType.network,
        message: 'Network error',
      );
    } on TimeoutException {
      return ApiResponse(
        status: 0,
        error: ApiErrorType.timeout,
        message: 'Request timeout',
      );
    } catch (e) {
      return ApiResponse(
        status: 0,
        error: ApiErrorType.unknown,
        message: e.toString(),
      );
    }
  }

  Future<http.Response?> _authorizedRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await TokenManager.instance.getValidAccessToken();
    if (token == null) return null;
    final url = Uri.parse('${ApiConstants.baseUrl}$path');

    Map<String, String> merged = {
      'accept': 'application/json',
      if (method != 'GET') 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    // If sending JSON and body is a Map/List, encode it.
    Object? effectiveBody = body;
    final ct = merged['Content-Type'];
    if (effectiveBody != null && ct == 'application/json') {
      if (effectiveBody is Map || effectiveBody is List) {
        try {
          effectiveBody = jsonEncode(effectiveBody);
        } catch (_) {
          // leave as is; decode error will surface downstream
        }
      }
    }

    http.Response res = await _send(method, url, merged, effectiveBody);
    if (res.statusCode == 401) {
      // Force a refresh explicitly (getValidAccessToken() might have reused an apparently-valid token)
      final outcome = await TokenManager.instance.forceRefresh();
      if (outcome.ok && outcome.pair != null) {
        merged['Authorization'] = 'Bearer ${outcome.pair!.accessToken}';
        res = await _send(method, url, merged, effectiveBody);
        return res;
      }
      // If refresh failed, do one fallback attempt with whatever token getValidAccessToken returns (in case another caller refreshed)
      final retryToken = await TokenManager.instance.getValidAccessToken();
      if (retryToken != null && retryToken != token) {
        merged['Authorization'] = 'Bearer $retryToken';
        res = await _send(method, url, merged, effectiveBody);
      }
    }
    return res;
  }

  Future<http.Response> _send(
    String method,
    Uri url,
    Map<String, String> headers,
    Object? body,
  ) async {
    switch (method) {
      case 'GET':
        return http.get(url, headers: headers);
      case 'POST':
        return http.post(url, headers: headers, body: body);
      case 'PATCH':
        return http.patch(url, headers: headers, body: body);
      case 'PUT':
        return http.put(url, headers: headers, body: body);
      case 'DELETE':
        return http.delete(url, headers: headers, body: body);
      default:
        throw UnsupportedError('Method $method not implemented');
    }
  }

  /// Convenience JSON helper
  dynamic decodeBody(http.Response? res) {
    if (res == null) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  ApiErrorType _mapStatusToError(int status) {
    if (status == 401 || status == 403) return ApiErrorType.unauthorized;
    if (status >= 400 && status < 500) return ApiErrorType.client;
    if (status >= 500) return ApiErrorType.server;
    return ApiErrorType.unknown;
  }
}
