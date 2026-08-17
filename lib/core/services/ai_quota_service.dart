import '../database/database.dart';
import '../providers/database_provider.dart';
import 'package:drift/drift.dart';

class AiQuotaService {
  final DatabaseProvider _databaseProvider;

  AiQuotaService(this._databaseProvider);

  static const int defaultDailyLimit = 10;

  /// Get remaining quota for today
  Future<int> getRemainingQuota() async {
    final db = _databaseProvider.database;
    return await db.getRemainingQuota();
  }

  /// Get today's usage count
  Future<int> getTodayUsage() async {
    final remaining = await getRemainingQuota();
    return defaultDailyLimit - remaining;
  }

  /// Check if user can make an AI request
  Future<bool> canMakeRequest() async {
    final remaining = await getRemainingQuota();
    return remaining > 0;
  }

  /// Increment AI usage after successful generation
  /// Returns true if successful, false if limit reached
  Future<bool> incrementUsage() async {
    final db = _databaseProvider.database;
    return await db.incrementAiUsage();
  }

  /// Get usage history for the past N days
  Future<List<AiUsageData>> getUsageHistory({int days = 30}) async {
    final db = _databaseProvider.database;
    return await db.getAiUsageHistory(limit: days);
  }

  /// Get quota status for UI display
  Future<QuotaStatus> getQuotaStatus() async {
    final remaining = await getRemainingQuota();
    final used = defaultDailyLimit - remaining;
    
    return QuotaStatus(
      used: used,
      remaining: remaining,
      limit: defaultDailyLimit,
      canRequest: remaining > 0,
      isLow: remaining <= 3,
    );
  }

  /// Reset quota (for testing or admin purposes)
  Future<bool> resetQuota() async {
    final db = _databaseProvider.database;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.getAiUsageForDate(dateStr);
    if (existing != null) {
      final updated = existing.copyWith(
        usedCount: 0,
        lastResetAt: today,
        updatedAt: DateTime.now(),
      );
      await db.update(db.aiUsage).replace(updated);
    }

    return true;
  }

  /// Authorized: Set custom daily limit for today
  Future<bool> setCustomDailyLimit(int newLimit) async {
    final db = _databaseProvider.database;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.getAiUsageForDate(dateStr);
    if (existing != null) {
      final updated = existing.copyWith(
        dailyLimit: newLimit,
        updatedAt: DateTime.now(),
      );
      await db.update(db.aiUsage).replace(updated);
    } else {
      // Create new entry with custom limit
      await db.into(db.aiUsage).insert(
        AiUsageCompanion(
          date: Value(dateStr),
          usedCount: const Value(0),
          dailyLimit: Value(newLimit),
          lastResetAt: Value(today),
        ),
      );
    }

    return true;
  }

  /// Authorized: Increase quota by specified amount
  Future<bool> increaseQuota(int amount) async {
    final db = _databaseProvider.database;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.getAiUsageForDate(dateStr);
    if (existing != null) {
      final newLimit = existing.dailyLimit + amount;
      final updated = existing.copyWith(
        dailyLimit: newLimit,
        updatedAt: DateTime.now(),
      );
      await db.update(db.aiUsage).replace(updated);
    } else {
      // Create new entry with increased limit
      await db.into(db.aiUsage).insert(
        AiUsageCompanion(
          date: Value(dateStr),
          usedCount: const Value(0),
          dailyLimit: Value(defaultDailyLimit + amount),
          lastResetAt: Value(today),
        ),
      );
    }

    return true;
  }

  /// Authorized: Decrease quota by specified amount
  Future<bool> decreaseQuota(int amount) async {
    final db = _databaseProvider.database;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.getAiUsageForDate(dateStr);
    if (existing != null) {
      final newLimit = (existing.dailyLimit - amount).clamp(0, existing.usedCount);
      final updated = existing.copyWith(
        dailyLimit: newLimit,
        updatedAt: DateTime.now(),
      );
      await db.update(db.aiUsage).replace(updated);
    }

    return true;
  }

  /// Authorized: Reset today's usage to zero
  Future<bool> resetTodayUsage() async {
    final db = _databaseProvider.database;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.getAiUsageForDate(dateStr);
    if (existing != null) {
      final updated = existing.copyWith(
        usedCount: 0,
        lastResetAt: today,
        updatedAt: DateTime.now(),
      );
      await db.update(db.aiUsage).replace(updated);
    }

    return true;
  }

  /// Authorized: Restore default daily limit
  Future<bool> restoreDefaultLimit() async {
    return await setCustomDailyLimit(defaultDailyLimit);
  }

  /// Get the last quota modification timestamp
  Future<DateTime?> getLastModificationTime() async {
    final db = _databaseProvider.database;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existing = await db.getAiUsageForDate(dateStr);
    return existing?.updatedAt;
  }
}

class QuotaStatus {
  final int used;
  final int remaining;
  final int limit;
  final bool canRequest;
  final bool isLow;

  QuotaStatus({
    required this.used,
    required this.remaining,
    required this.limit,
    required this.canRequest,
    required this.isLow,
  });

  String get displayText => '$remaining / $limit';
  
  String get message {
    if (!canRequest) {
      return 'Daily limit reached ($limit/$limit). Try again tomorrow.';
    } else if (isLow) {
      return 'Only $remaining request(s) remaining today.';
    } else {
      return '$remaining requests remaining today.';
    }
  }
}
