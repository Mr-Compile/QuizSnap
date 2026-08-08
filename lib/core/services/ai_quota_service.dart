import '../database/database.dart';
import '../providers/database_provider.dart';

class AiQuotaService {
  final DatabaseProvider _databaseProvider;

  AiQuotaService(this._databaseProvider);

  static const int dailyLimit = 15;

  /// Get remaining quota for today
  Future<int> getRemainingQuota() async {
    final db = _databaseProvider.database;
    return await db.getRemainingQuota();
  }

  /// Get today's usage count
  Future<int> getTodayUsage() async {
    final remaining = await getRemainingQuota();
    return dailyLimit - remaining;
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
  Future<List<AiUsage>> getUsageHistory({int days = 30}) async {
    final db = _databaseProvider.database;
    return await db.getAiUsageHistory(limit: days);
  }

  /// Get quota status for UI display
  Future<QuotaStatus> getQuotaStatus() async {
    final remaining = await getRemainingQuota();
    final used = dailyLimit - remaining;
    
    return QuotaStatus(
      used: used,
      remaining: remaining,
      limit: dailyLimit,
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
      await (db.update(db.aiUsage)..where((tbl) => tbl.id.equals(existing.id))).write(
        AiUsageCompanion(
          usedCount: const Value(0),
          lastResetAt: Value(today),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    
    return true;
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