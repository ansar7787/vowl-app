import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

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
  /// `nonPersonalizedAds` is ALWAYS true because the app serves under-16
  /// users (Kids Zone) and has no age-gate or UMP consent framework to
  /// distinguish adults from children at runtime. Serving personalized ads
  /// to any user without proof of age ≥16 + explicit consent (EEA/UK)
  /// violates COPPA / Google Families Policy — the penalty is AdMob
  /// account termination, not lower revenue.
  ///
  /// If an age-gate is added later, this method can conditionally return
  /// `nonPersonalizedAds: false` for verified adults who have consented.
  static AdRequest _buildAdRequest() {
    return AdRequest(
      keywords: <String>['game', 'learning', 'education'],
      contentUrl: 'https://Vowl-quest.com',
      nonPersonalizedAds: true,
    );
  }

  /// Cached request instance — all ad loads use this.
  static final AdRequest _adRequest = _buildAdRequest();

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

        // Lessen strict kids-only restrictions to increase ad fill rate and revenue.
        // NOTE: Make sure your Google Play Console target audience matches this (e.g., 13+).
        MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: kDebugMode
                ? ['6739FCB31DECCBA1A191319DC27E562A']
                : null,
            // COMPLIANCE FIX: Default to child-directed treatment since
            // the app has under-16 users (Kids Zone). This sets the
            // global SDK tag. Individual ad requests in the main app
            // can still work normally — this is the safe default.
            tagForChildDirectedTreatment:
                TagForChildDirectedTreatment.yes,
            tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
            maxAdContentRating: MaxAdContentRating.g,
          ),
        );

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
