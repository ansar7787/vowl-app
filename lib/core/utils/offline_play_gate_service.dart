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
class OfflinePlayGateService {
  OfflinePlayGateService._();
  static final OfflinePlayGateService instance = OfflinePlayGateService._();

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

  /// Records that a level was completed while offline.
  /// Returns `true` if the quota is now exhausted (should block further play).
  bool recordOfflineLevel() {
    _offlineLevelsPlayed++;
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
  }

  /// Grants additional offline plays after watching a rewarded ad.
  /// Unlike [resetQuotaAfterAd], this extends the current count
  /// by [maxOfflineLevels] rather than resetting to zero, so the
  /// total session offline plays are still tracked.
  void grantBonusOfflinePlays() {
    _offlineLevelsPlayed =
        (_offlineLevelsPlayed - maxOfflineLevels).clamp(0, 999);
    _pendingReconnectAdReset = false;
  }
}
