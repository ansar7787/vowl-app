import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/remote_config_service.dart';

/// Manages daily limits for free currency claims (Keys and Magic Stars)
/// to prevent Premium users (or free users) from spamming the "Claim" or
/// "Watch Ad" buttons indefinitely and breaking the game economy.
class RewardLimitService {
  static int get maxClaimsPerDay {
    try {
      return di.sl<RemoteConfigService>().dailyRewardLimit;
    } catch (_) {
      return 5;
    }
  }

  static String _getKeyForType(String rewardType) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return 'reward_claims_${rewardType}_$today';
  }

  /// Checks if the user has reached their daily limit for a specific reward type.
  /// [rewardType] should be 'keys', 'stars', 'coins', or 'hints'.
  static Future<bool> hasReachedDailyLimit(String rewardType) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_getKeyForType(rewardType)) ?? 0;
    return count >= maxClaimsPerDay;
  }

  /// Increments the daily claim count for a specific reward type.
  static Future<void> incrementClaimCount(String rewardType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForType(rewardType);
    final count = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, count + 1);
  }

  /// Gets the remaining claims for a specific reward type.
  static Future<int> getRemainingClaims(String rewardType) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_getKeyForType(rewardType)) ?? 0;
    return (maxClaimsPerDay - count).clamp(0, maxClaimsPerDay);
  }
}
