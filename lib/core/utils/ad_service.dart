import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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

  static const AdRequest _adRequest = AdRequest(
    keywords: <String>['game', 'learning', 'education'],
    contentUrl: 'https://Vowl-quest.com',
    nonPersonalizedAds: true,
  );

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  bool _isInitialized = false;

  /// Initialises the Google Mobile Ads SDK and begins pre-loading ads.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// Non-blocking: SDK init and ad loading run in the background so the
  /// UI thread is never stalled.
  Future<void> init() async {
    if (kIsWeb || _isInitialized) return;

    try {
      MobileAds.instance.initialize().then((status) {
        _isInitialized = true;
        if (kDebugMode) debugPrint('AdService: MobileAds initialised.');

        // Enforce COPPA/Families Policy compliance globally for all users
        // This is strictly required to prevent AdMob bans for kids games.
        MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: kDebugMode ? ['6739FCB31DECCBA1A191319DC27E562A'] : null,
            tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
            maxAdContentRating: MaxAdContentRating.g,
          ),
        );

        // Stagger ad loading to avoid competing with app startup rendering.
        Future.delayed(const Duration(seconds: 2), loadInterstitialAd);
        Future.delayed(const Duration(seconds: 4), loadRewardedAd);
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
          if (_numInterstitialLoadAttempts <= _maxFailedLoadAttempts) {
            final delay = Duration(seconds: 2 * _numInterstitialLoadAttempts);
            if (kDebugMode) {
              debugPrint(
                'AdService: Retrying interstitial in ${delay.inSeconds}s…',
              );
            }
            Future.delayed(delay, loadInterstitialAd);
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

  /// Whether a rewarded ad is ready to show.
  bool get isRewardedAdLoaded => _rewardedAd != null;

  void loadRewardedAd() {
    final adUnitId = _rewardedAdUnitId();
    if (adUnitId.isEmpty) {
      _reportMissingAdUnit('ADMOB_REWARDED is empty. Ads will not load.');
      return;
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: _adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) debugPrint('AdService: Rewarded ad loaded.');
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint(
              'AdService: Rewarded failed (${error.code}): ${error.message}',
            );
          }
          _numRewardedLoadAttempts++;
          _rewardedAd = null;
          if (_numRewardedLoadAttempts <= _maxFailedLoadAttempts) {
            final delay = Duration(seconds: 2 * _numRewardedLoadAttempts);
            if (kDebugMode) {
              debugPrint(
                'AdService: Retrying rewarded in ${delay.inSeconds}s…',
              );
            }
            Future.delayed(delay, loadRewardedAd);
          }
        },
      ),
    );
  }

  void showRewardedAd({
    required bool isPremium,
    required Function(RewardItem) onUserEarnedReward,
    required VoidCallback onDismissed,
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
    required bool isPremium,
    required VoidCallback onHintEarned,
    required VoidCallback onDismissed,
  }) {
    showRewardedAd(
      isPremium: isPremium,
      onUserEarnedReward: (_) => onHintEarned(),
      onDismissed: onDismissed,
    );
  }
}
