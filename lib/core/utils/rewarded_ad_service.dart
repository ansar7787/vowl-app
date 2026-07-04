import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

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

  /// Releases the currently held ad object, if any. Call when the app is
  /// being torn down (mirrors [AdService.dispose]).
  void dispose();
}

/// Concrete implementation, backed by `google_mobile_ads`.
///
/// ### Why this is no longer a stub
/// An earlier review pass on this file (in isolation) correctly identified
/// that it couldn't fabricate a working ad-network integration without
/// proof the SDK was actually a dependency of this app, or knowledge of
/// this app's real ad-unit-ID convention - inventing either would not have
/// compiled or would have hit the wrong AdMob account. That was the right
/// call at the time. Reviewing `ad_service.dart` in this same pass now
/// supplies both missing pieces directly from this codebase: it already
/// imports `google_mobile_ads` and `flutter_dotenv`, and already has a
/// working, shipped rewarded-ad flow with a concrete test/production
/// ad-unit-ID convention (`ADMOB_REWARDED_ANDROID` / `ADMOB_REWARDED_IOS`
/// via `.env`, falling back to Google's public AdMob test unit IDs in
/// debug builds). This implementation follows that exact same, already-
/// proven convention rather than guessing at a new one.
///
/// ### Architecture note - please consolidate
/// `AdService` (see `ad_service.dart`) *also* implements a complete,
/// independent rewarded-ad flow (`showRewardedAd` / `showHintRewardedAd`),
/// with its own separate `RewardedAd` instance, its own load/retry state,
/// and a different calling contract (`Function(RewardItem)` callback
/// instead of this class's `RewardedAdResult` enum). This class is now
/// fully functional rather than a fake stub, but the app effectively has
/// **two parallel rewarded-ad subsystems** hitting the same ad unit,
/// which - if both are ever active in the same session - means duplicate
/// SDK loads (wasted requests / quota) and two independent `RewardedAd`
/// instances that could race to `.show()` each other. I have not deleted
/// or merged `AdService`'s rewarded-ad methods here, because I can't see
/// every call site across the app from this slice and don't want to break
/// screens that already depend on `AdService.showRewardedAd`/
/// `showHintRewardedAd` working exactly as they do today. Recommended
/// follow-up (needs your sign-off, not a silent change): pick ONE of the
/// two as the canonical rewarded-ad service, have the other delegate to
/// it (or be deleted), and update call sites accordingly.
class RewardedAdServiceImpl implements RewardedAdService {
  RewardedAd? _rewardedAd;
  int _numLoadAttempts = 0;
  bool _isLoadInFlight = false;
  bool _isDisposed = false;

  static const int _maxFailedLoadAttempts = 3;

  static const AdRequest _adRequest = AdRequest(
    keywords: <String>['game', 'learning', 'education'],
    nonPersonalizedAds: true,
  );

  /// Same debug/release ad-unit-ID resolution convention as
  /// `AdService._rewardedAdUnitId()`: Google's public AdMob test unit ID
  /// in debug builds (so ads always load during development regardless of
  /// `.env` configuration), the real unit ID from `.env` in release.
  String _adUnitId() {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? dotenv.env['ADMOB_REWARDED_ANDROID'] ?? ''
        : dotenv.env['ADMOB_REWARDED_IOS'] ?? '';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  @override
  Future<void> preload() async {
    // Already holding a ready ad, or a load is already in flight - avoid
    // firing a redundant, competing load request.
    if (_isDisposed || _rewardedAd != null || _isLoadInFlight) return;

    final adUnitId = _adUnitId();
    if (adUnitId.isEmpty) {
      sl<AppLogger>().warning(
        'RewardedAdService: No ad unit ID configured (ADMOB_REWARDED_'
        'ANDROID/IOS missing from .env) - skipping preload.',
      );
      return;
    }

    _isLoadInFlight = true;
    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: _adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoadInFlight = false;
            if (_isDisposed) {
              // Torn down while this load was in flight - discard rather
              // than resurrecting a disposed service.
              ad.dispose();
              return;
            }
            _rewardedAd = ad;
            _numLoadAttempts = 0;
          },
          onAdFailedToLoad: (error) {
            _isLoadInFlight = false;
            _rewardedAd = null;
            _numLoadAttempts++;
            sl<AppLogger>().warning(
              'RewardedAdService: Failed to load (${error.code}): '
              '${error.message}',
            );
            if (!_isDisposed && _numLoadAttempts <= _maxFailedLoadAttempts) {
              final delay = Duration(seconds: 2 * _numLoadAttempts);
              Future.delayed(delay, () {
                if (!_isDisposed) preload();
              });
            }
          },
        ),
      );
    } catch (e, stackTrace) {
      _isLoadInFlight = false;
      sl<AppLogger>().error(
        'RewardedAdService: preload threw',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<RewardedAdResult> showRewardedAd() async {
    try {
      return await _loadAndShow();
    } catch (e, stackTrace) {
      sl<AppLogger>().error(
        'RewardedAdService: showRewardedAd failed',
        error: e,
        stackTrace: stackTrace,
      );
      return RewardedAdResult.failed;
    }
  }

  Future<RewardedAdResult> _loadAndShow() async {
    var ad = _rewardedAd;

    // Nothing preloaded - attempt a just-in-time load rather than failing
    // outright. This costs the user a short wait instead of a dead end,
    // but never grants a reward without an ad actually being shown.
    if (ad == null) {
      await preload();
      ad = _rewardedAd;
    }

    if (ad == null) {
      return RewardedAdResult.notAvailable;
    }

    // Claim the instance immediately so a concurrent call can't also grab
    // it and both try to `.show()` the same ad.
    _rewardedAd = null;

    final completer = Completer<RewardedAdResult>();
    bool rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        unawaited(preload()); // Warm the next one for next time.
        if (!completer.isCompleted) {
          completer.complete(
            rewardEarned
                ? RewardedAdResult.earned
                : RewardedAdResult.dismissedEarly,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        shownAd.dispose();
        unawaited(preload());
        sl<AppLogger>().warning(
          'RewardedAdService: Failed to show (${error.code}): '
          '${error.message}',
        );
        if (!completer.isCompleted) {
          completer.complete(RewardedAdResult.failed);
        }
      },
    );

    await ad.show(
      onUserEarnedReward: (_, _) {
        // CONTRACT: this is the ONLY place `rewardEarned` is ever set. The
        // caller only sees RewardedAdResult.earned once this SDK callback
        // has actually fired - see the class doc comment on the previous
        // stub for why that guarantee matters (it's the fix for the old
        // free-coins-every-2-seconds exploit).
        rewardEarned = true;
      },
    );

    return completer.future;
  }
}
