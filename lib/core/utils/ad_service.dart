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
  static const int levelsPerInterstitial = 2;

  /// Minimum minutes between interstitials (safety net).
  static const int interstitialCooldownMinutes = 3;
  static const int maxFailedLoadAttempts = 3;

  static final AdRequest request = AdRequest(
    keywords: const <String>['game', 'learning', 'education'],
    contentUrl: 'https://voxai-quest.com',
    nonPersonalizedAds: true,
  );

  // ─── Lifecycle ──────────────────────────────────────────────────────

  Future<void> init() async {
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      loadInterstitialAd();
      loadRewardedAd(); // Pre-load so rewarded ads are ready when needed
      loadAppOpenAd();
    }
  }

  // ─── Interstitial ──────────────────────────────────────────────────

  void loadInterstitialAd() {
    final adUnitId = Platform.isAndroid
        ? dotenv.env['ADMOB_INTERSTITIAL_ANDROID'] ?? ''
        : dotenv.env['ADMOB_INTERSTITIAL_IOS'] ?? '';

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
  }) {
    // Premium bypass
    if (isPremium || _interstitialAd == null) {
      onDismissed();
      return;
    }

    // Pacing: Don't show if cooldown hasn't passed
    final now = DateTime.now();
    if (_lastInterstitialTime != null) {
      final difference = now.difference(_lastInterstitialTime!);
      if (difference.inMinutes < interstitialCooldownMinutes) {
        debugPrint(
          'AdService: Interstitial skipped (${interstitialCooldownMinutes}min cooldown)',
        );
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

  // ─── Banner Ads ────────────────────────────────────────────────────

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  bool get isBannerLoaded => _isBannerLoaded;
  BannerAd? get bannerAd => _bannerAd;

  void loadBannerAd() {
    final adUnitId = Platform.isAndroid
        ? dotenv.env['ADMOB_BANNER_ANDROID'] ??
              'ca-app-pub-3940256099942544/6300978111' // Test ID
        : dotenv.env['ADMOB_BANNER_IOS'] ??
              'ca-app-pub-3940256099942544/2934735716'; // Test ID

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _isBannerLoaded = true;
          debugPrint('AdService: Banner ad loaded');
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _isBannerLoaded = false;
          ad.dispose();
          debugPrint('AdService: Banner ad failed: $error');
        },
      ),
    );
    _bannerAd!.load();
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
  }

  // ─── Rewarded Ads ──────────────────────────────────────────────────

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  void loadRewardedAd() {
    final adUnitId = Platform.isAndroid
        ? dotenv.env['ADMOB_REWARDED_ANDROID'] ??
              'ca-app-pub-3940256099942544/5224354917'
        : dotenv.env['ADMOB_REWARDED_IOS'] ??
              'ca-app-pub-3940256099942544/1712485313';

    RewardedAd.load(
      adUnitId: adUnitId,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _numRewardedLoadAttempts += 1;
          _rewardedAd = null;
          if (_numRewardedLoadAttempts <= maxFailedLoadAttempts) {
            loadRewardedAd();
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
      debugPrint('Warning: Attempted to show rewarded ad before loaded.');
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

  // ─── App Open Ads ──────────────────────────────────────────────────

  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  DateTime? _appOpenLoadTime;

  void loadAppOpenAd() {
    final adUnitId = Platform.isAndroid
        ? dotenv.env['ADMOB_APP_OPEN_ANDROID'] ??
              'ca-app-pub-3940256099942544/9257395921'
        : dotenv.env['ADMOB_APP_OPEN_IOS'] ??
              'ca-app-pub-3940256099942544/5575463023';

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: request,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  bool get _isAppOpenAdAvailable {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        DateTime.now().difference(_appOpenLoadTime!).inHours < 4;
  }

  void showAppOpenAdIfAvailable({required bool isPremium}) {
    if (isPremium) return;
    if (!_isAppOpenAdAvailable || _isShowingAppOpenAd) {
      loadAppOpenAd();
      return;
    }

    _isShowingAppOpenAd = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }
}
