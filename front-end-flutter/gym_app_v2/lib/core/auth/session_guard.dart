import 'package:flutter/widgets.dart';
import '../logging/app_logger.dart';
import 'token_manager.dart';
import '../../services/log_out_service.dart';

/// Resolution result for a persistent 401 after retry.
enum UnauthorizedResolution { none, softFail, logout }

/// Central guard to decide how to act when an API call keeps returning 401.
/// Policy:
/// 1. Attempt explicit refresh (single-flight handled by TokenManager).
/// 2. If refresh fatal -> logout.
/// 3. If refresh soft (network/server/unknown) -> softFail (UI may show retry).
/// 4. If refresh success but still 401 at caller site -> softFail (anomaly but not forcing logout immediately).
class SessionGuard {
  SessionGuard._();
  static bool _resolving = false;

  static Future<UnauthorizedResolution> handlePersistent401({
    BuildContext? context,
    String source = '',
  }) async {
    if (_resolving) {
      AppLogger.debug(
        'SessionGuard: already resolving 401, return softFail (source=$source)',
      );
      return UnauthorizedResolution.softFail; // avoid storm
    }
    _resolving = true;
    try {
      final outcome = await TokenManager.instance.forceRefresh();
      if (!outcome.ok) {
        switch (outcome.status) {
          case RefreshStatus.invalidToken:
          case RefreshStatus.noRefreshToken:
          case RefreshStatus.decodeError:
            AppLogger.info(
              'SessionGuard: fatal refresh -> logout (source=$source)',
              tag: 'SessionGuard',
            );
            if (context != null) {
              await LogoutService.logout(
                context,
                reason: 'fatal_refresh_${outcome.status.name}',
              );
            }
            return UnauthorizedResolution.logout;
          case RefreshStatus.networkError:
          case RefreshStatus.serverError:
          case RefreshStatus.unknownError:
            AppLogger.info(
              'SessionGuard: soft refresh fail (${outcome.status}) (source=$source)',
              tag: 'SessionGuard',
            );
            return UnauthorizedResolution.softFail;
          case RefreshStatus.success:
            // unreachable path here (since !ok) but keep for completeness
            return UnauthorizedResolution.none;
        }
      }
      // Refresh success -> let caller decide if they want to retry original request.
      AppLogger.debug(
        'SessionGuard: refresh success after 401 (source=$source)',
      );
      return UnauthorizedResolution.none; // means caller may retry
    } catch (e, st) {
      AppLogger.error(
        'SessionGuard unexpected error: $e',
        tag: 'SessionGuard',
        stackTrace: st,
        error: e,
      );
      return UnauthorizedResolution.softFail;
    } finally {
      _resolving = false;
    }
  }
}
