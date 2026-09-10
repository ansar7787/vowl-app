import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks and limits offline gameplay for free (non-premium) users.
///
/// ### Business Logic
/// Free users are granted a small offline grace period ([maxOfflineLevels])
/// to handle real-world scenarios like slow/rain networks without freezing
/// the game. Once the quota is exhausted, the user must either:
///
///  1. **Reconnect** — an interstitial ad is shown on reconnection, then
///     the quota resets.
///  2. **Watch a cached rewarded ad** — grants [maxOfflineLevels] more
///     offline plays without needing to reconnect.
///  3. **Go Premium** — unlimited offline play, no ads.
///
/// Premium users bypass this limiter entirely via [NetworkInfo.setPremiumOverride],
/// which makes their connectivity stream always emit [AppNetworkStatus.online].
///
/// ### Quota Reset Rules
/// - Resets ONLY when an ad is successfully shown (interstitial on reconnect
///   OR rewarded ad while offline). This prevents the "toggle WiFi for 1 sec"
///   loophole where a user could reset the counter without ever seeing an ad.
/// - [resetQuotaAfterAd] is the sole reset method. There is intentionally
///   no "free" reset.
///
/// ### Persistence
/// The counter and timestamp are persisted to [SharedPreferences] so that
/// force-killing the app does not reset the quota. If the stored timestamp
/// is older than 24 hours the quota auto-resets on [init].
class OfflinePlayGateService extends ChangeNotifier {
  OfflinePlayGateService._();
  static final OfflinePlayGateService instance = OfflinePlayGateService._();

  /// SharedPreferences key for the offline levels played counter.
  static const String _kOfflineLevelsKey = 'offline_levels_played';

  /// SharedPreferences key for the timestamp when offline play started.
  static const String _kOfflineTimestampKey = 'offline_levels_timestamp';

  /// Maximum number of levels a free user can complete while offline
  /// before being required to reconnect or watch an ad.
  static const int maxOfflineLevels = 3;

  /// Number of levels played during the current offline window.
  int _offlineLevelsPlayed = 0;

  /// Flag: set to true when user reconnects. The quota only resets
  /// once an ad has been shown after reconnection.
  bool _pendingReconnectAdReset = false;

  /// Whether the offline grace quota has been exhausted.
  bool get isOfflineQuotaExhausted => _offlineLevelsPlayed >= maxOfflineLevels;

  /// Current count of levels played offline.
  int get offlineLevelsPlayed => _offlineLevelsPlayed;

  /// Remaining offline plays before the gate closes.
  int get remainingOfflinePlays =>
      (maxOfflineLevels - _offlineLevelsPlayed).clamp(0, maxOfflineLevels);

  /// Whether a reconnect-triggered ad reset is pending.
  bool get hasPendingReconnectReset => _pendingReconnectAdReset;

  /// Loads the persisted counter from [SharedPreferences].
  ///
  /// If the stored timestamp is older than 24 hours the quota is
  /// automatically reset to 0 — this prevents stale counters from
  /// blocking users who haven't played in a long time.
  ///
  /// Should be called once during app startup (e.g. in `main()`).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCount = prefs.getInt(_kOfflineLevelsKey) ?? 0;
    final storedTimestamp = prefs.getInt(_kOfflineTimestampKey);

    if (storedTimestamp != null) {
      final storedTime = DateTime.fromMillisecondsSinceEpoch(storedTimestamp);
      final elapsed = DateTime.now().difference(storedTime);

      if (elapsed.inHours >= 24) {
        // Quota expired — auto-reset.
        _offlineLevelsPlayed = 0;
        await prefs.remove(_kOfflineLevelsKey);
        await prefs.remove(_kOfflineTimestampKey);
        return;
      }
    }

    _offlineLevelsPlayed = storedCount;
  }

  /// Records that a level was completed while offline.
  /// Returns `true` if the quota is now exhausted (should block further play).
  bool recordOfflineLevel() {
    _offlineLevelsPlayed++;
    _persist();
    notifyListeners();
    return isOfflineQuotaExhausted;
  }

  /// Called when the device comes back online. Marks that an ad should be
  /// shown before resetting the quota. Does NOT reset the counter itself —
  /// [resetQuotaAfterAd] does that after the ad completes.
  void markReconnected() {
    if (_offlineLevelsPlayed > 0) {
      _pendingReconnectAdReset = true;
    }
  }

  /// Resets the offline counter after an ad has been successfully shown.
  /// This is the ONLY way to reset the quota — ensuring the developer
  /// always earns ad revenue before granting more offline plays.
  ///
  /// Called from:
  ///  - Interstitial ad dismissed callback (on reconnect)
  ///  - Rewarded ad earned callback (offline "watch ad for +3 levels")
  void resetQuotaAfterAd() {
    _offlineLevelsPlayed = 0;
    _pendingReconnectAdReset = false;
    _persist(clear: true);
    notifyListeners();
  }

  /// Grants additional offline plays after watching a rewarded ad.
  /// Unlike [resetQuotaAfterAd], this extends the current count
  /// by [maxOfflineLevels] rather than resetting to zero, so the
  /// total session offline plays are still tracked.
  void grantBonusOfflinePlays() {
    _offlineLevelsPlayed = (_offlineLevelsPlayed - maxOfflineLevels).clamp(
      0,
      999,
    );
    _pendingReconnectAdReset = false;
    _persist();
    notifyListeners();
  }

  /// Persists the current counter and timestamp to [SharedPreferences].
  ///
  /// When [clear] is `true` the stored values are removed instead
  /// (used after a full quota reset).
  ///
  /// Fire-and-forget — callers do not await this.
  void _persist({bool clear = false}) {
    SharedPreferences.getInstance().then((prefs) {
      if (clear) {
        prefs.remove(_kOfflineLevelsKey);
        prefs.remove(_kOfflineTimestampKey);
      } else {
        prefs.setInt(_kOfflineLevelsKey, _offlineLevelsPlayed);
        prefs.setInt(
          _kOfflineTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    });
  }
}
