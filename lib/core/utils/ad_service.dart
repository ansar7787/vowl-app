import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdService {
  // ─── Interstitial Ads ───────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  DateTime? _lastInterstitialTime;

  /// Levels completed since the last interstitial was shown.
  int _completedLevelsSinceLastAd = 0;

  /// Show an interstitial every N completed levels.
  static const int levelsPerInterstitial = 3;

  /// Minimum minutes between interstitials (safety net).
  static const int interstitialCooldownMinutes = 3;
  static const int maxFailedLoadAttempts = 3;

  static final AdRequest request = AdRequest(
    keywords: const <String>['game', 'learning', 'education'],
    contentUrl: 'https://Vowl-quest.com',
    nonPersonalizedAds: true,
  );

  // ─── Lifecycle ──────────────────────────────────────────────────────

  bool _isInitialized = false;

  Future<void> init() async {
    if (kIsWeb || _isInitialized) return;

    try {
      // Initialize without awaiting to prevent blocking the UI thread
      MobileAds.instance.initialize().then((status) {
        _isInitialized = true;
        if (kDebugMode) {
          debugPrint('AdService: MobileAds initialized');
        }

        // Configure test device IDs only in debug mode
        if (kDebugMode) {
          MobileAds.instance.updateRequestConfiguration(
            RequestConfiguration(testDeviceIds: ["6739FCB31DECCBA1A191319DC27E562A"]),
          );
        }

        // Load ads with a slight staggered delay to keep the UI smooth during startup
        Future.delayed(const Duration(seconds: 2), () => loadInterstitialAd());
        Future.delayed(const Duration(seconds: 4), () => loadRewardedAd());
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdService: Initialization error: $e');
      }
    }
  }

  // ─── Interstitial ──────────────────────────────────────────────────

  void loadInterstitialAd() {
    String adUnitId;
    if (kDebugMode) {
      // Standard Google Test Interstitial ID
      adUnitId = Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/1033173712' 
          : 'ca-app-pub-3940256099942544/4411468910';
    } else {
      adUnitId = Platform.isAndroid
          ? dotenv.env['ADMOB_INTERSTITIAL_ANDROID'] ?? ''
          : dotenv.env['ADMOB_INTERSTITIAL_IOS'] ?? '';
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  /// Call after every level completion. Returns true if we should show
  /// an interstitial (i.e. user has completed `levelsPerInterstitial` levels).
  bool recordLevelCompletion() {
    _completedLevelsSinceLastAd++;
    return _completedLevelsSinceLastAd >= levelsPerInterstitial;
  }

  void showInterstitialAd({
    required VoidCallback onDismissed,
    required bool isPremium,
    bool isLevelCompletion = true,
  }) {
    // 1. Increment counter on level completion
    if (isLevelCompletion) {
      _completedLevelsSinceLastAd++;
    }

    // 2. Premium bypass
    if (isPremium) {
      onDismissed();
      return;
    }

    // 3. Frequency check (Enforce levelsPerInterstitial globally)
    if (_completedLevelsSinceLastAd < levelsPerInterstitial) {
      if (kDebugMode) {
        debugPrint(
          'AdService: Interstitial skipped (Level completion count: $_completedLevelsSinceLastAd/$levelsPerInterstitial)',
        );
      }
      onDismissed();
      return;
    }

    // 4. Availability check
    if (_interstitialAd == null) {
      if (kDebugMode) {
        debugPrint('AdService: Interstitial skipped (Ad not loaded)');
      }
      onDismissed();
      return;
    }

    // 5. Pacing cooldown
    final now = DateTime.now();
    if (_lastInterstitialTime != null) {
      final difference = now.difference(_lastInterstitialTime!);
      if (difference.inMinutes < interstitialCooldownMinutes) {
        if (kDebugMode) {
          debugPrint(
            'AdService: Interstitial skipped (${interstitialCooldownMinutes}min cooldown)',
          );
        }
        onDismissed();
        return;
      }
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        _lastInterstitialTime = DateTime.now();
        _completedLevelsSinceLastAd = 0; // Reset counter after showing
        ad.dispose();
        loadInterstitialAd();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        loadInterstitialAd();
        onDismissed();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ─── Rewarded Ads ──────────────────────────────────────────────────

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  bool get isRewardedAdLoaded => _rewardedAd != null;

  void loadRewardedAd() {
    String adUnitId;
    if (kDebugMode) {
      // Standard Google Test Rewarded ID
      adUnitId = Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/5224354917' 
          : 'ca-app-pub-3940256099942544/1712485313';
    } else {
      adUnitId = Platform.isAndroid
          ? dotenv.env['ADMOB_REWARDED_ANDROID'] ?? ''
          : dotenv.env['ADMOB_REWARDED_IOS'] ?? '';
    }

    if (adUnitId.isEmpty) {
      if (kDebugMode) {
        debugPrint('AdService: Missing rewarded ad unit ID in .env');
      }
      return;
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (kDebugMode) {
            debugPrint('AdService: Rewarded ad loaded.');
          }
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            debugPrint('AdService: Rewarded ad failed to load: ${error.message} (Code: ${error.code})');
          }
          _numRewardedLoadAttempts += 1;
          _rewardedAd = null;
          if (_numRewardedLoadAttempts <= maxFailedLoadAttempts) {
            // Retry with exponential backoff delay (2s, 4s, 8s...)
            final delay = Duration(seconds: 2 * _numRewardedLoadAttempts);
            if (kDebugMode) {
              debugPrint('AdService: Retrying rewarded load in ${delay.inSeconds}s...');
            }
            Future.delayed(delay, () => loadRewardedAd());
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
        debugPrint('Warning: Attempted to show rewarded ad before loaded.');
      }
      onDismissed();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        loadRewardedAd();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        loadRewardedAd();
        onDismissed();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
      },
    );
    _rewardedAd = null;
  }

  void showHintRewardedAd({
    required bool isPremium,
    required VoidCallback onHintEarned,
    required VoidCallback onDismissed,
  }) {
    showRewardedAd(
      isPremium: isPremium,
      onUserEarnedReward: (reward) {
        onHintEarned();
      },
      onDismissed: onDismissed,
    );
  }
}
