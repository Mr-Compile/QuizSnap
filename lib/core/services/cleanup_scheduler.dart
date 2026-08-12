import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import 'trash_cleanup_service.dart';

/// Schedules and coordinates periodic trash cleanup.
///
/// This class is intentionally lightweight. It does not start an Isolate by
/// default, but exposes the hooks needed to wire one in later when the app
/// scales. Call [runIfNeeded] from `main.dart` at startup.
class CleanupScheduler {
  final AppDatabase _database;
  final SharedPreferences _prefs;
  Timer? _dailyTimer;

  CleanupScheduler({
    required this._database,
    required this._prefs,
  });

  /// Runs one cleanup immediately and, if [scheduleDaily] is true, starts a
  /// 24-hour repeating timer. Disable until scaling requirements increase.
  void runIfNeeded({bool scheduleDaily = false}) {
    unawaited(TrashCleanupService.cleanupIfNeeded(_database, _prefs));

    if (scheduleDaily) {
      _dailyTimer?.cancel();
      _dailyTimer = Timer.periodic(
        const Duration(days: 1),
        (_) => unawaited(TrashCleanupService.cleanupIfNeeded(_database, _prefs)),
      );
    }
  }

  /// Manually trigger a cleanup now.
  Future<void> runNow() => TrashCleanupService.cleanupIfNeeded(_database, _prefs);

  /// Stop the daily timer. Safe to call even if no timer is running.
  void stop() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
  }

  void dispose() {
    stop();
  }
}
