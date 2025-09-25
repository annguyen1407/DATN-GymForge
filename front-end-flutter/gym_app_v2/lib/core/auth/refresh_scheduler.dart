import 'dart:async';
import '../logging/app_logger.dart';
import 'token_manager.dart';

/// Simplified fixed-interval refresh scheduler.
/// Starts after login, stops on logout.
class RefreshScheduler {
  RefreshScheduler._();
  static final RefreshScheduler instance = RefreshScheduler._();

  Timer? _timer;
  // Default production interval (can be overridden via .env in main())
  Duration interval = const Duration(minutes: 10);

  bool get running => _timer != null;

  Future<void> start({bool immediate = true}) async {
    stop();
    final prettyInterval = interval.inMinutes >= 2
        ? '${interval.inMinutes}m'
        : '${interval.inSeconds}s';
    AppLogger.info(
      'Starting RefreshScheduler interval=$prettyInterval immediate=$immediate',
      tag: 'RefreshScheduler',
    );
    if (immediate) {
      // Immediate normalization refresh; TokenManager itself logs the outcome.
      final outcome = await TokenManager.instance.forceRefresh();
      if (!outcome.ok &&
          (outcome.status == RefreshStatus.invalidToken ||
              outcome.status == RefreshStatus.noRefreshToken ||
              outcome.status == RefreshStatus.decodeError)) {
        AppLogger.info(
          'Immediate fatal outcome (${outcome.status}) -> abort scheduling',
          tag: 'RefreshScheduler',
        );
        return;
      }
    }
    _timer = Timer.periodic(interval, (_) async {
      final outcome = await TokenManager.instance.forceRefresh();
      if (!outcome.ok &&
          (outcome.status == RefreshStatus.invalidToken ||
              outcome.status == RefreshStatus.noRefreshToken ||
              outcome.status == RefreshStatus.decodeError)) {
        AppLogger.info(
          'Fatal refresh outcome=${outcome.status} -> stopping',
          tag: 'RefreshScheduler',
        );
        stop();
      }
      // Success & soft failures are already logged by TokenManager compact log.
    });
  }

  void stop() {
    if (_timer != null) {
      AppLogger.info('Stopping RefreshScheduler', tag: 'RefreshScheduler');
    }
    _timer?.cancel();
    _timer = null;
  }
}
