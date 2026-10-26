import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/remote_config_service.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'dart:async';

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
  /// Base value is 3, modulated by Remote Config `ad_frequency_multiplier`.
  /// A multiplier of 2.0 means ads show twice as often (every 1.5 levels → rounds to 2).
  /// A multiplier of 0.5 means ads show half as often (every 6 levels).
  static int get levelsPerInterstitial {
    try {
      final multiplier = di.sl<RemoteConfigService>().adFrequencyMultiplier;
      if (multiplier <= 0) return 3; // Safety: avoid division by zero
      return (3 / multiplier).round().clamp(1, 10);
    } catch (_) {
      return 3; // Fallback if RemoteConfigService not yet registered
    }
  }

  /// Minimum cooldown between interstitials regardless of level count.
  /// Modulated by Remote Config to maximize revenue while remaining compliant.
  static int get interstitialCooldownMinutes {
    try {
      return di.sl<RemoteConfigService>().interstitialCooldownMinutes;
    } catch (_) {
      return 3;
    }
  }

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
        testDeviceIds: kDebugMode ? ['6739FCB31DECCBA1A191319DC27E562A'] : null,
        ageRestrictedTreatment: isAdult
            ? AgeRestrictedTreatment.unspecified
            : AgeRestrictedTreatment.child,
        maxAdContentRating: isAdult
            ? MaxAdContentRating.ma
            : MaxAdContentRating.g,
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
    bool force = false,
  }) {
    // 1. Premium bypass — never show ads to premium users.
    if (isPremium) {
      onDismissed();
      return;
    }

    // 2. Frequency gate — enforce levelsPerInterstitial policy.
    //    FIX (CRITICAL-3): No internal increment here. The counter was
    //    already updated by recordLevelCompletion() before this call.
    if (!force && _completedLevelsSinceLastAd < levelsPerInterstitial) {
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
    if (!force && _lastInterstitialTime != null) {
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
  final List<void Function(bool success)> _adLoadListeners = [];

  /// Whether a rewarded ad is ready to show.
  bool get isRewardedAdLoaded => _rewardedAd != null;

  /// Actively waits up to [timeout] for a rewarded ad to load if one is not already ready.
  Future<bool> waitForRewardedAd({
    Duration timeout = const Duration(milliseconds: 3500),
  }) async {
    if (_rewardedAd != null) return true;
    loadRewardedAd();
    final completer = Completer<bool>();
    void listener(bool success) {
      if (!completer.isCompleted) completer.complete(success);
    }

    _adLoadListeners.add(listener);
    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => false,
      );
    } finally {
      _adLoadListeners.remove(listener);
    }
  }

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
          final listeners = List<void Function(bool)>.from(_adLoadListeners);
          _adLoadListeners.clear();
          for (final l in listeners) {
            l(true);
          }
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
          final listeners = List<void Function(bool)>.from(_adLoadListeners);
          _adLoadListeners.clear();
          for (final l in listeners) {
            l(false);
          }
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

  Future<void> showRewardedAd({
    BuildContext? context,
    required bool isPremium,
    required Function(RewardItem) onUserEarnedReward,
    required VoidCallback onDismissed,

    /// When true, forces child-safe ad request parameters.
    /// All Kids Zone call sites should pass `childSafe: true`.
    bool childSafe = false,
  }) async {
    if (isPremium) {
      onUserEarnedReward(RewardItem(1, 'Premium Reward'));
      onDismissed();
      return;
    }

    // COPPA FIX: If childSafe is requested but the pre-loaded ad was built
    // with personalized params (adult user in Kids Zone), dispose it and
    // reload with a forced child-safe request. This ensures COPPA compliance
    // regardless of the age gate result.
    if (childSafe && (_rewardedAd == null || AgeGateService.isAdultCached)) {
      if (_rewardedAd != null) {
        _rewardedAd!.dispose();
        _rewardedAd = null;
      }
      _loadAndShowChildSafeRewarded(
        context: context,
        onUserEarnedReward: onUserEarnedReward,
        onDismissed: onDismissed,
      );
      return;
    }

    if (_rewardedAd == null) {
      loadRewardedAd();

      if (context != null && context.mounted) {
        final networkInfo = di.sl.isRegistered<NetworkInfo>()
            ? di.sl<NetworkInfo>()
            : null;
        final hasRealConnection = networkInfo != null
            ? await networkInfo.hasRealConnection
            : true;

        if (!hasRealConnection) {
          if (context.mounted) {
            CustomSnackBar.show(
              context: context,
              message: context.tr(
                'connectivity.no_internet_for_ads',
                fallback:
                    'No internet connection. Please check your network to watch ads.',
              ),
              type: CustomSnackBarType.warning,
            );
          }
          onDismissed();
          return;
        }

        bool isCancelled = false;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => _AdLoadingDialog(
            onCancel: () {
              isCancelled = true;
              Navigator.of(dialogCtx).pop();
            },
          ),
        );

        final isLoaded = await waitForRewardedAd(
          timeout: const Duration(milliseconds: 3500),
        );

        if (context.mounted && !isCancelled) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (isCancelled) {
          onDismissed();
          return;
        }

        if (!isLoaded || _rewardedAd == null) {
          if (context.mounted) {
            CustomSnackBar.show(
              context: context,
              message: context.tr(
                'games.ad_loading_retry',
                fallback:
                    'Ad is still loading. Please try again in a few moments.',
              ),
              type: CustomSnackBarType.warning,
            );
          }
          onDismissed();
          return;
        }
      } else {
        onDismissed();
        return;
      }
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
            message: context.tr(
              'games.failed_to_show_ad',
              fallback:
                  'Failed to show ad. Please check your internet and try again.',
            ),
            type: CustomSnackBarType.warning,
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

  /// Loads a fresh rewarded ad with forced child-safe request parameters,
  /// then shows it immediately upon successful load.
  ///
  /// Used when an adult user enters Kids Zone — the pre-loaded ad was built
  /// with personalized params, so we must reload with COPPA-compliant settings.
  void _loadAndShowChildSafeRewarded({
    BuildContext? context,
    required Function(RewardItem) onUserEarnedReward,
    required VoidCallback onDismissed,
  }) {
    final adUnitId = _rewardedAdUnitId();
    if (adUnitId.isEmpty) {
      onDismissed();
      return;
    }

    final childSafeRequest = _buildAdRequest(forceChildSafe: true);

    Timer? timeoutTimer;
    bool hasCompleted = false;
    bool isCancelled = false;

    if (context != null && context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => _AdLoadingDialog(
          onCancel: () {
            isCancelled = true;
            hasCompleted = true;
            timeoutTimer?.cancel();
            Navigator.of(dialogCtx).pop();
            onDismissed();
          },
        ),
      );
    }

    timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (hasCompleted) return;
      hasCompleted = true;
      if (kDebugMode) {
        debugPrint('AdService: Child-safe rewarded ad load timed out.');
      }
      if (context != null && context.mounted && !isCancelled) {
        Navigator.of(context, rootNavigator: true).pop();
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'games.ad_loading_retry',
            fallback:
                'Ad is still loading. Please try again in a few moments.',
          ),
          type: CustomSnackBarType.warning,
        );
      }
      onDismissed();
    });

    RewardedAd.load(
      adUnitId: adUnitId,
      request: childSafeRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (hasCompleted) {
            ad.dispose();
            return;
          }
          hasCompleted = true;
          timeoutTimer?.cancel();

          if (context != null && context.mounted && !isCancelled) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (isCancelled || _isDisposed) {
            ad.dispose();
            onDismissed();
            return;
          }

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadRewardedAd(); // Reload normal ad for next time
              onDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) {
                debugPrint(
                  'AdService: Child-safe rewarded failed to show: $error',
                );
              }
              ad.dispose();
              loadRewardedAd();
              onDismissed();
            },
          );

          ad.setImmersiveMode(true);
          ad.show(
            onUserEarnedReward: (_, reward) => onUserEarnedReward(reward),
          );
        },
        onAdFailedToLoad: (error) {
          if (hasCompleted) return;
          hasCompleted = true;
          timeoutTimer?.cancel();

          if (context != null && context.mounted && !isCancelled) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (kDebugMode) {
            debugPrint(
              'AdService: Child-safe rewarded load failed (${error.code}): ${error.message}',
            );
          }
          if (context != null && context.mounted && !isCancelled) {
            CustomSnackBar.show(
              context: context,
              message: context.tr(
                'games.ad_loading_retry',
                fallback:
                    'Ad is still loading. Please try again in a few moments.',
              ),
              type: CustomSnackBarType.warning,
            );
          }
          loadRewardedAd(); // Reload normal ad for next time
          onDismissed();
        },
      ),
    );
  }
}

/// Modern 2026 gaming ad preparation dialog shown while an ad prepares or buffers.
class _AdLoadingDialog extends StatelessWidget {
  final VoidCallback onCancel;

  const _AdLoadingDialog({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onCancel();
      },
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 280.w,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 1.5.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo500.withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo500, AppColors.violet500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: VowlButtonSpinner(
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  context.tr('store.loading_ad', fallback: 'Loading Ad...'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  context.tr(
                    'games.preparing_reward',
                    fallback: 'Preparing your reward...',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : AppColors.slate500,
                  ),
                ),
                SizedBox(height: 24.h),
                ScaleButton(
                  onTap: onCancel,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        context.tr('common.cancel', fallback: 'CANCEL'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white70 : AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
