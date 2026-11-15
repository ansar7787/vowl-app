import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks and limits offline gameplay for free (non-premium) users.
///
/// ### Business Logic (Daily Offline Allowance Model)
/// Free users are granted a daily allowance ([maxOfflineLevels] = 3) of offline
/// levels to handle real-world connectivity dips (e.g. subways, spotty signals)
/// without interrupting gameplay.
///
/// Once the daily quota is exhausted, the user can:
///  1. **Connect to Internet** — online play is always 100% free and unlimited
///     (monetized with standard in-game ads). Reconnecting does NOT reset the
///     daily offline quota, closing the "airplane mode toggle" exploit.
///  2. **Watch a Cached Rewarded Ad** — grants bonus offline plays (+3 plays)
///     without needing an internet connection.
///  3. **Go Premium** — unlimited offline play everywhere with zero ads.
///
/// ### Quota Expiration & Reset
/// - The daily offline allowance rolls over every **24 hours** from when the
///   first offline level was recorded.
/// - Watching a rewarded ad grants bonus plays immediately via [grantBonusOfflinePlays].
/// - Reconnecting to Wi-Fi does NOT grant free offline resets, protecting ad
///   revenue and premium subscriptions.
class OfflinePlayGateService extends ChangeNotifier {
  OfflinePlayGateService._();
  static final OfflinePlayGateService instance = OfflinePlayGateService._();

  /// SharedPreferences key for the offline levels played counter.
  static const String _kOfflineLevelsKey = 'offline_levels_played';

  /// SharedPreferences key for the timestamp when the current offline window began.
  static const String _kOfflineTimestampKey = 'offline_levels_timestamp';

  /// Maximum number of daily free offline levels allowed before requiring
  /// online connectivity, a rewarded ad, or Premium.
  static const int maxOfflineLevels = 3;

  /// Number of levels played during the current daily offline window.
  int _offlineLevelsPlayed = 0;

  /// Timestamp in milliseconds when the current daily offline window started.
  int? _offlineWindowTimestamp;

  /// Flag: set to true when user reconnects with pending offline play stats.
  bool _pendingReconnectAdReset = false;

  final StreamController<int> _remainingPlaysController =
      StreamController<int>.broadcast();

  /// Reactive stream emitting the current number of remaining offline plays.
  Stream<int> get onRemainingPlaysChange => _remainingPlaysController.stream;

  /// Checks if 24 hours have elapsed since the current daily window began.
  /// If expired, automatically rolls over the quota to a fresh 3 plays.
  bool _checkAndApplyDailyReset() {
    if (_offlineWindowTimestamp != null) {
      final storedTime =
          DateTime.fromMillisecondsSinceEpoch(_offlineWindowTimestamp!);
      final elapsed = DateTime.now().difference(storedTime);

      if (elapsed.inHours >= 24) {
        _offlineLevelsPlayed = 0;
        _offlineWindowTimestamp = null;
        _pendingReconnectAdReset = false;
        _persist(clear: true);
        return true;
      }
    }
    return false;
  }

  /// Whether the daily offline quota has been completely exhausted.
  bool get isOfflineQuotaExhausted {
    _checkAndApplyDailyReset();
    return _offlineLevelsPlayed >= maxOfflineLevels;
  }

  /// Current count of levels played in the active daily window.
  int get offlineLevelsPlayed {
    _checkAndApplyDailyReset();
    return _offlineLevelsPlayed;
  }

  /// Remaining free offline plays before the offline gate blocks further play.
  int get remainingOfflinePlays {
    _checkAndApplyDailyReset();
    return (maxOfflineLevels - _offlineLevelsPlayed).clamp(0, maxOfflineLevels);
  }

  /// Whether a reconnect state flag is active.
  bool get hasPendingReconnectReset => _pendingReconnectAdReset;

  void _notify() {
    if (!_remainingPlaysController.isClosed) {
      _remainingPlaysController.add(remainingOfflinePlays);
    }
    notifyListeners();
  }

  /// Loads the persisted counter and daily window timestamp from [SharedPreferences].
  ///
  /// If the stored timestamp is older than 24 hours, the daily quota is
  /// automatically reset.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCount = prefs.getInt(_kOfflineLevelsKey) ?? 0;
    final storedTimestamp = prefs.getInt(_kOfflineTimestampKey);

    _offlineWindowTimestamp = storedTimestamp;
    _offlineLevelsPlayed = storedCount;

    if (_checkAndApplyDailyReset()) {
      _notify();
      return;
    }

    _notify();
  }

  /// Records that a level was completed while offline.
  /// If [isPremium] is true, this is a no-op because premium users have
  /// unlimited offline gameplay.
  /// Returns `true` if the quota is now exhausted (should block further offline play).
  bool recordOfflineLevel({bool isPremium = false}) {
    if (isPremium) return false;
    _checkAndApplyDailyReset();

    // Start daily window clock on first offline level
    _offlineWindowTimestamp ??= DateTime.now().millisecondsSinceEpoch;

    _offlineLevelsPlayed++;
    _persist();
    _notify();
    return isOfflineQuotaExhausted;
  }

  /// Marks that the device has reconnected to the internet.
  void markReconnected() {
    if (_offlineLevelsPlayed > 0) {
      _pendingReconnectAdReset = true;
    }
  }

  /// Explicitly resets the offline counter (e.g. manual admin or test cleanup).
  void resetQuotaAfterAd() {
    _offlineLevelsPlayed = 0;
    _offlineWindowTimestamp = null;
    _pendingReconnectAdReset = false;
    _persist(clear: true);
    _notify();
  }

  /// Grants additional offline plays after watching a rewarded ad.
  void grantBonusOfflinePlays() {
    _offlineLevelsPlayed = (_offlineLevelsPlayed - maxOfflineLevels).clamp(
      0,
      999,
    );
    _pendingReconnectAdReset = false;
    _persist();
    _notify();
  }

  /// Persists the current counter and timestamp to [SharedPreferences].
  void _persist({bool clear = false}) {
    SharedPreferences.getInstance().then((prefs) {
      if (clear) {
        prefs.remove(_kOfflineLevelsKey);
        prefs.remove(_kOfflineTimestampKey);
      } else {
        prefs.setInt(_kOfflineLevelsKey, _offlineLevelsPlayed);
        if (_offlineWindowTimestamp != null) {
          prefs.setInt(_kOfflineTimestampKey, _offlineWindowTimestamp!);
        }
      }
    });
  }
}
