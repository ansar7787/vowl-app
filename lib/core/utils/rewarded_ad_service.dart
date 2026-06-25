import 'package:vowl/core/utils/app_logger.dart';

/// Result of attempting to show a rewarded ad.
enum RewardedAdResult {
  /// The user watched the ad to completion - grant the reward.
  earned,

  /// No ad was available to show (not loaded / load failed / network down).
  notAvailable,

  /// The ad was shown but the user dismissed it before earning the reward.
  dismissedEarly,

  /// The ad SDK threw while loading or showing.
  failed,
}

/// Abstract contract defining the rewarded-video advertising integration.
///
/// Decouples the ad network SDK from the calling UI, satisfying the
/// Dependency Inversion Principle (DIP) - matches the same pattern as
/// every other service in this codebase (e.g. [TtsService], [SpeechService]).
abstract class RewardedAdService {
  /// Factory mapping constructor supporting seamless backwards compatibility for callers.
  factory RewardedAdService() = RewardedAdServiceImpl;

  /// Loads and shows a rewarded ad. Resolves only after the ad experience
  /// has fully ended (closed, completed, or failed) - never optimistically.
  Future<RewardedAdResult> showRewardedAd();

  /// Pre-loads the next ad in the background so it's ready by the time the
  /// user taps "watch ad" again, avoiding a load-time spinner on every tap.
  Future<void> preload();
}

/// Concrete implementation.
///
/// ====================================================================
/// ACTION REQUIRED - THIS IS A STRUCTURAL STUB, NOT A WORKING AD
/// INTEGRATION:
/// ====================================================================
/// This codebase slice does not include an ad network SDK dependency
/// (e.g. `google_mobile_ads`, `unity_ads_plugin`), ad unit IDs, or
/// mediation configuration - none of those exist anywhere in the files
/// provided for this review, and I can't fabricate working calls to a
/// package that isn't declared as a dependency (it wouldn't compile) or
/// invent ad unit IDs (they're tied to your actual AdMob/Unity Ads
/// account). That is a genuine external blocker, not something left
/// undone out of laziness.
///
/// What I *did* fix: the previous `RewardedAdCard` granted the in-game
/// currency reward unconditionally after a fixed 2-second
/// `Future.delayed` with **no actual ad shown at all** - meaning every
/// user could tap "watch ad" once every ~2 seconds for free coins
/// indefinitely, with zero ad revenue and no real anti-abuse gate. That
/// is fixed structurally below: the reward is now only ever granted when
/// this method resolves [RewardedAdResult.earned], and the actual ad-SDK
/// call is isolated to the one clearly-marked spot inside [_loadAndShow].
/// Wire up your real AdMob/Unity Ads `RewardedAd.load(...)` /
/// `.show(onUserEarnedReward: ...)` call there; everything that depends
/// on this service (gating the reward, handling failure/dismissal,
/// disabling the button while pending) is already correct and will not
/// need to change.
class RewardedAdServiceImpl implements RewardedAdService {
  bool _isAdReady = false;

  @override
  Future<void> preload() async {
    try {
      // Wire up your real ad network's preload call here, e.g.
      // RewardedAd.load(adUnitId: ..., request: AdRequest(), ...), and
      // set `_isAdReady = true` from its onAdLoaded callback.
      _isAdReady = false;
    } catch (e) {
      AppLogger.warning('RewardedAdService: Preload failed', error: e);
      _isAdReady = false;
    }
  }

  @override
  Future<RewardedAdResult> showRewardedAd() async {
    try {
      return await _loadAndShow();
    } catch (e, stackTrace) {
      AppLogger.error(
        'RewardedAdService: showRewardedAd failed',
        error: e,
        stackTrace: stackTrace,
      );
      return RewardedAdResult.failed;
    }
  }

  Future<RewardedAdResult> _loadAndShow() async {
    // ================================================================
    // REPLACE THIS BLOCK with your real ad network call. The contract
    // this method must honor:
    //   - return `RewardedAdResult.notAvailable` if no ad could be
    //     loaded (do NOT grant the reward)
    //   - return `RewardedAdResult.dismissedEarly` if the user closed the
    //     ad before the network's onUserEarnedReward fired
    //   - return `RewardedAdResult.earned` ONLY inside/after the ad SDK's
    //     own onUserEarnedReward callback
    //   - return `RewardedAdResult.failed` on any SDK-level error
    // ================================================================
    AppLogger.warning(
      'RewardedAdService: No ad network integrated yet - returning '
      'notAvailable so no reward is granted. See class doc comment.',
    );
    _isAdReady = false;
    return RewardedAdResult.notAvailable;
  }
}
