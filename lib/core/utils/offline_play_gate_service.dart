/// Tracks and limits offline gameplay for free (non-premium) users.
///
/// ### Business Logic
/// Free users are granted a small offline grace period ([maxOfflineLevels])
/// to handle real-world scenarios like slow/rain networks without freezing
/// the game. Once the quota is exhausted, the user must reconnect to
/// continue — ensuring ad impressions are not permanently bypassed.
///
/// Premium users bypass this limiter entirely via [NetworkInfo.setPremiumOverride],
/// which makes their connectivity stream always emit [AppNetworkStatus.online].
///
/// ### Quota Reset
/// The counter resets to 0 whenever the device comes back online, giving the
/// user a fresh grace buffer for the next offline window.
class OfflinePlayGateService {
  OfflinePlayGateService._();
  static final OfflinePlayGateService instance = OfflinePlayGateService._();

  /// Maximum number of levels a free user can complete while offline
  /// before being required to reconnect. This number is intentionally
  /// small — just enough to cover temporary network blips (rain, tunnel,
  /// elevator) without enabling permanent ad-free offline play.
  static const int maxOfflineLevels = 3;

  /// Number of levels played during the current offline window.
  int _offlineLevelsPlayed = 0;

  /// Whether the offline grace quota has been exhausted.
  bool get isOfflineQuotaExhausted => _offlineLevelsPlayed >= maxOfflineLevels;

  /// Current count of levels played offline.
  int get offlineLevelsPlayed => _offlineLevelsPlayed;

  /// Remaining offline plays before the gate closes.
  int get remainingOfflinePlays =>
      (maxOfflineLevels - _offlineLevelsPlayed).clamp(0, maxOfflineLevels);

  /// Records that a level was completed while offline.
  /// Returns `true` if the quota is now exhausted (should block further play).
  bool recordOfflineLevel() {
    _offlineLevelsPlayed++;
    return isOfflineQuotaExhausted;
  }

  /// Resets the counter. Called when the device comes back online.
  void resetQuota() {
    _offlineLevelsPlayed = 0;
  }
}
