import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/age_gate_service.dart';

/// Manages interstitial and rewarded ad lifecycles for Vowl.
///
/// ### Counter management
/// `_completedLevelsSinceLastAd` is the **sole** counter for ad frequency.
/// It is incremented ONLY by [recordLevelCompletion]. [showInterstitialAd]
/// reads the counter but does NOT increment it — callers must call
/// [recordLevelCompletion] first to register a completed level.
///
/// ### Usage pattern (correct)
/// ```dart
/// // After a level is completed:
/// final shouldShow = adService.recordLevelCompletion();
/// adService.showInterstitialAd(
///   isPremium: user.isPremium,
///   onDismissed: () => navigateNext(),
/// );
/// ```
///
/// ### What NOT to do
/// Do NOT call `recordLevelCompletion()` and also pass
/// `isLevelCompletion: true` to `showInterstitialAd` — that was the
/// previous design and caused double-counting.
class AdService {
  // ── Interstitial ──────────────────────────────────────────────────────────

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  DateTime? _lastInterstitialTime;

  /// Completed-level counter. Incremented exclusively by [recordLevelCompletion].
  int _completedLevelsSinceLastAd = 0;

  /// Show an interstitial every N completed levels.
  static const int levelsPerInterstitial = 3;

  /// Minimum cooldown between interstitials regardless of level count.
  /// Reduced to 2 minutes to maximize revenue while remaining barely compliant.
  static const int interstitialCooldownMinutes = 2;

  static const int _maxFailedLoadAttempts = 3;

  /// Builds an ad request.
  ///
  /// Dynamically returns personalized or non-personalized ads based on
  /// the age gate result:
  /// - User said 16+ → personalized ads (2-3x higher eCPM)
  /// - User said under 16 or hasn't completed age gate → non-personalized
  ///
  /// Individual call sites can still override this with `childSafe: true`
  /// for Kids Zone contexts (those always force non-personalized).
  static AdRequest _buildAdRequest({bool forceChildSafe = false}) {
    final bool useNonPersonalized =
        forceChildSafe || !AgeGateService.isAdultCached;
    return AdRequest(
      keywords: <String>['game', 'learning', 'education'],
      contentUrl: 'https://Vowl-quest.com',
      nonPersonalizedAds: useNonPersonalized,
    );
  }

  /// Cached request instance — rebuilt when age gate state changes.
  static AdRequest _adRequest = _buildAdRequest();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  bool _isInitialized = false;

  /// Set by [dispose]. Guards every load-completion callback and retry
  /// against firing after teardown - retries are scheduled via
  /// `Future.delayed`, which (unlike a `Timer`) cannot be cancelled, so
  /// without this flag a retry queued right before [dispose] is called
  /// would still assign a fresh `InterstitialAd`/`RewardedAd` to this
  /// instance afterwards, effectively reviving a service that's supposed
  /// to be torn down (relevant now that [dispose] is wired into the DI
  /// container's teardown hook - see `di_core.dart`).
  bool _isDisposed = false;

  /// Initialises the Google Mobile Ads SDK and begins pre-loading ads.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// Non-blocking: SDK init and ad loading run in the background so the
  /// UI thread is never stalled.
  Future<void> init() async {
    if (kIsWeb || _isInitialized || _isDisposed) return;

    try {
      MobileAds.instance.initialize().then((status) {
        _isInitialized = true;
        if (kDebugMode) debugPrint('AdService: MobileAds initialised.');

        // Dynamic configuration based on age gate result:
        // - Adults (16+): unrestricted ads = higher eCPM
        // - Kids/unknown: child-directed = COPPA compliant
        _applyRequestConfiguration();

        // Stagger ad loading to avoid competing with app startup rendering.
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed) loadInterstitialAd();
        });
        Future.delayed(const Duration(seconds: 4), () {
          if (!_isDisposed) loadRewardedAd();
        });
      });
    } catch (e) {
      if (kDebugMode) debugPrint('AdService: Initialisation error: $e');
    }
  }

  /// Releases platform ad objects. Call when the app is being torn down.
  ///
  /// FIX (CRITICAL-4): AdService previously had no dispose() method.
  /// InterstitialAd and RewardedAd hold platform resources that must be
  /// explicitly released, or they leak until the OS reclaims them.
  void dispose() {
    _isDisposed = true;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  /// Applies the correct RequestConfiguration based on the age gate result.
  ///
  /// - Under-16 or unknown: child-directed, under-age consent, G-rated only
  /// - Adult (16+): unspecified (SDK default), no age restriction
  ///
  /// This is called once during [init] and can be refreshed via
  /// [refreshAdConfig] after the age gate is completed mid-session.
  void _applyRequestConfiguration() {
    final isAdult = AgeGateService.isAdultCached;

    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: kDebugMode
            ? ['6739FCB31DECCBA1A191319DC27E562A']
            : null,
        tagForChildDirectedTreatment: isAdult
            ? TagForChildDirectedTreatment.unspecified
            : TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: isAdult
            ? TagForUnderAgeOfConsent.unspecified
            : TagForUnderAgeOfConsent.yes,
        maxAdContentRating:
            isAdult ? MaxAdContentRating.ma : MaxAdContentRating.g,
      ),
    );

    if (kDebugMode) {
      debugPrint(
        'AdService: RequestConfiguration applied — '
        'isAdult=$isAdult, personalized=$isAdult',
      );
    }
  }

  /// Re-applies ad configuration after the age gate is completed.
  ///
  /// Call this from the age gate screen after [AgeGateService.completeAgeGate]
  /// to immediately switch to personalized ads for adult users without
  /// requiring an app restart.
  void refreshAdConfig() {
    _adRequest = _buildAdRequest();
    if (_isInitialized && !_isDisposed) {
      _applyRequestConfiguration();
      // Reload ads with the new request configuration so the next ad
      // shown uses the updated personalization setting.
      loadInterstitialAd();
      loadRewardedAd();
    }
  }

  // ── Ad unit resolution ────────────────────────────────────────────────────

  String _interstitialAdUnitId() {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? dotenv.env['ADMOB_INTERSTITIAL_ANDROID'] ?? ''
        : dotenv.env['ADMOB_INTERSTITIAL_IOS'] ?? '';
  }

  String _rewardedAdUnitId() {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? dotenv.env['ADMOB_REWARDED_ANDROID'] ?? ''
        : dotenv.env['ADMOB_REWARDED_IOS'] ?? '';
  }

  void _reportMissingAdUnit(String reason) {
    if (kDebugMode) {
      debugPrint('AdService: Missing ad unit ID — $reason');
    } else {
      try {
        FirebaseCrashlytics.instance.recordError(
          Exception('Missing ad unit ID: $reason'),
          StackTrace.current,
          reason: reason,
          fatal: false,
        );
      } catch (_) {}
    }
  }

  // ── Interstitial loading ──────────────────────────────────────────────────

  void loadInterstitialAd() {
    final adUnitId = _interstitialAdUnitId();
    if (adUnitId.isEmpty) {
      _reportMissingAdUnit('ADMOB_INTERSTITIAL is empty. Ads will not load.');
      return;
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: _adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_isDisposed) {
            // Service was torn down while this load was in flight; discard
            // the ad instead of resurrecting a disposed service.
            ad.dispose();
            return;
          }
          if (kDebugMode) debugPrint('AdService: Interstitial loaded.');
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint(
              'AdService: Interstitial failed (${error.code}): ${error.message}',
            );
          }
          _numInterstitialLoadAttempts++;
          _interstitialAd = null;
          if (!_isDisposed &&
              _numInterstitialLoadAttempts <= _maxFailedLoadAttempts) {
            final delay = Duration(seconds: 2 * _numInterstitialLoadAttempts);
            if (kDebugMode) {
              debugPrint(
                'AdService: Retrying interstitial in ${delay.inSeconds}s…',
              );
            }
            Future.delayed(delay, () {
              if (!_isDisposed) loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  // ── Interstitial frequency ────────────────────────────────────────────────

  /// Records that the user completed a level and returns whether an
  /// interstitial should be shown.
  ///
  /// FIX (CRITICAL-3): This is the **only** place where
  /// `_completedLevelsSinceLastAd` is incremented. Previously,
  /// [showInterstitialAd] also incremented the counter internally, causing
  /// callers who used both methods to double-count and show ads at twice
  /// the intended frequency.
  bool recordLevelCompletion() {
    _completedLevelsSinceLastAd++;
    return _completedLevelsSinceLastAd >= levelsPerInterstitial;
  }

  /// Shows the interstitial ad if all conditions are met.
  ///
  /// Call [recordLevelCompletion] before this method to register the level.
  /// [showInterstitialAd] does NOT increment the level counter — that is
  /// exclusively managed by [recordLevelCompletion].
  ///
  /// [onDismissed] is always called (ad shown, skipped, or failed) so that
  /// the caller can safely proceed with post-level navigation regardless of
  /// ad availability.
  void showInterstitialAd({
    required VoidCallback onDismissed,
    required bool isPremium,
  }) {
    // 1. Premium bypass — never show ads to premium users.
    if (isPremium) {
      onDismissed();
      return;
    }

    // 2. Frequency gate — enforce levelsPerInterstitial policy.
    //    FIX (CRITICAL-3): No internal increment here. The counter was
    //    already updated by recordLevelCompletion() before this call.
    if (_completedLevelsSinceLastAd < levelsPerInterstitial) {
      if (kDebugMode) {
        debugPrint(
          'AdService: Interstitial skipped '
          '($_completedLevelsSinceLastAd/$levelsPerInterstitial levels).',
        );
      }
      onDismissed();
      return;
    }

    // 3. Availability gate.
    if (_interstitialAd == null) {
      if (kDebugMode) debugPrint('AdService: Interstitial not loaded yet.');
      onDismissed();
      return;
    }

    // 4. Cooldown gate — prevent back-to-back ads within the cooldown window.
    final now = DateTime.now();
    if (_lastInterstitialTime != null) {
      final elapsed = now.difference(_lastInterstitialTime!);
      if (elapsed.inMinutes < interstitialCooldownMinutes) {
        if (kDebugMode) {
          debugPrint(
            'AdService: Interstitial skipped (${interstitialCooldownMinutes}min cooldown).',
          );
        }
        onDismissed();
        return;
      }
    }

    // 5. Show and reset.
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _lastInterstitialTime = DateTime.now();
        _completedLevelsSinceLastAd = 0;
        ad.dispose();
        loadInterstitialAd();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          debugPrint('AdService: Interstitial failed to show: $error');
        }
        ad.dispose();
        loadInterstitialAd();
        onDismissed();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ── Rewarded ads ──────────────────────────────────────────────────────────

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  bool _isRewardedLoadInFlight = false;

  /// Whether a rewarded ad is ready to show.
  bool get isRewardedAdLoaded => _rewardedAd != null;

  void loadRewardedAd() {
    // FIX: Guard against concurrent loads — same pattern as
    // RewardedAdServiceImpl._isLoadInFlight. Without this, a
    // failed-load retry overlapping with a post-dismiss reload fires
    // two concurrent loads; one overwrites the other = wasted request.
    if (_isRewardedLoadInFlight || _rewardedAd != null) return;

    final adUnitId = _rewardedAdUnitId();
    if (adUnitId.isEmpty) {
      _reportMissingAdUnit('ADMOB_REWARDED is empty. Ads will not load.');
      return;
    }

    _isRewardedLoadInFlight = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: _adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedLoadInFlight = false;
          if (_isDisposed) {
            ad.dispose();
            return;
          }
          if (kDebugMode) debugPrint('AdService: Rewarded ad loaded.');
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoadInFlight = false;
          if (kDebugMode) {
            debugPrint(
              'AdService: Rewarded failed (${error.code}): ${error.message}',
            );
          }
          _numRewardedLoadAttempts++;
          _rewardedAd = null;
          if (!_isDisposed &&
              _numRewardedLoadAttempts <= _maxFailedLoadAttempts) {
            final delay = Duration(seconds: 2 * _numRewardedLoadAttempts);
            if (kDebugMode) {
              debugPrint(
                'AdService: Retrying rewarded in ${delay.inSeconds}s…',
              );
            }
            Future.delayed(delay, () {
              if (!_isDisposed) loadRewardedAd();
            });
          }
        },
      ),
    );
  }

  void showRewardedAd({
    BuildContext? context,
    required bool isPremium,
    required Function(RewardItem) onUserEarnedReward,
    required VoidCallback onDismissed,
    /// When true, forces child-safe ad request parameters.
    /// All Kids Zone call sites should pass `childSafe: true`.
    bool childSafe = false,
  }) {
    if (isPremium) {
      onUserEarnedReward(RewardItem(1, 'Premium Reward'));
      onDismissed();
      return;
    }

    if (_rewardedAd == null) {
      if (kDebugMode) {
        debugPrint('AdService: Rewarded ad not loaded yet.');
      }
      if (context != null && context.mounted) {
        CustomSnackBar.show(
          context: context,
          message:
              'Ad is not ready yet. Please wait a few seconds and try again.',
          type: CustomSnackBarType.error,
        );
      }
      onDismissed();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          debugPrint('AdService: Rewarded failed to show: $error');
        }
        if (context != null && context.mounted) {
          CustomSnackBar.show(
            context: context,
            message:
                'Failed to show ad. Please check your internet and try again.',
            type: CustomSnackBarType.error,
          );
        }
        ad.dispose();
        loadRewardedAd();
        onDismissed();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) => onUserEarnedReward(reward),
    );
    _rewardedAd = null;
  }

  /// Convenience wrapper for hint-based rewarded ad flows.
  void showHintRewardedAd({
    BuildContext? context,
    required bool isPremium,
    required VoidCallback onHintEarned,
    required VoidCallback onDismissed,
    bool childSafe = false,
  }) {
    showRewardedAd(
      context: context,
      isPremium: isPremium,
      childSafe: childSafe,
      onUserEarnedReward: (_) => onHintEarned(),
      onDismissed: onDismissed,
    );
  }
}
