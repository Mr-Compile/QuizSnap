import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../database/database.dart';

/// Background-style trash cleanup service.
///
/// Removes items whose `deletedAt` is older than [retentionDays].
/// Preferences are stored in [SharedPreferences].
class TrashCleanupService {
  static const String _autoDeleteEnabledKey = 'trash_auto_delete_enabled';
  static const String _lastCleanupKey = 'trash_last_cleanup';
  static const int retentionDays = 30;

  static bool _shouldRun(SharedPreferences prefs) {
    return prefs.getBool(_autoDeleteEnabledKey) ?? true;
  }

  static Future<DateTime?> lastCleanup(SharedPreferences prefs) async {
    final ms = prefs.getInt(_lastCleanupKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setAutoDeleteEnabled(
    SharedPreferences prefs,
    bool enabled,
  ) async {
    await prefs.setBool(_autoDeleteEnabledKey, enabled);
  }

  static Future<bool> isAutoDeleteEnabled(SharedPreferences prefs) async {
    return prefs.getBool(_autoDeleteEnabledKey) ?? true;
  }

  /// Runs the cleanup if auto-delete is enabled.
  /// This is safe to call at app startup; it returns immediately and completes
  /// the DB work in a [Future] on the same isolate.
  static Future<void> cleanupIfNeeded(
    AppDatabase database,
    SharedPreferences prefs,
  ) async {
    if (!_shouldRun(prefs)) return;

    try {
      final cutoff = DateTime.now().subtract(
        const Duration(days: retentionDays),
      );

      final deletedDecks = await database.getDeletedDecks();
      for (final deck in deletedDecks) {
        if (deck.deletedAt != null && deck.deletedAt!.isBefore(cutoff)) {
          try {
            await database.permanentlyDeleteDeck(deck.id);
          } catch (e) {
            debugPrint('Trash cleanup: failed to delete deck ${deck.id}: $e');
          }
        }
      }

      final deletedFlashcards = await database.getDeletedFlashcards();
      for (final card in deletedFlashcards) {
        if (card.deletedAt != null && card.deletedAt!.isBefore(cutoff)) {
          try {
            await database.permanentlyDeleteFlashcard(card.id);
          } catch (e) {
            debugPrint('Trash cleanup: failed to delete card ${card.id}: $e');
          }
        }
      }

      await prefs.setInt(_lastCleanupKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Trash cleanup error: $e');
    }
  }

  /// Force a manual cleanup now regardless of the auto-delete setting.
  static Future<void> runNow(
    AppDatabase database,
    SharedPreferences prefs,
  ) async {
    return cleanupIfNeeded(database, prefs);
  }
}
