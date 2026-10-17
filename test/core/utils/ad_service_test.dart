// ignore_for_file: implementation_imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/remote_config_service.dart';

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRemoteConfigService mockRemoteConfig;
  late List<MethodCall> channelCalls;
  late AdService adService;
  int? lastLoadedInterstitialAdId;
  int? lastLoadedRewardedAdId;

  Future<void> simulateAdEvent(
    int adId,
    String eventName, [
    Map<dynamic, dynamic>? extra,
  ]) async {
    final Map<dynamic, dynamic> arguments = {
      'adId': adId,
      'eventName': eventName,
      if (extra != null) ...extra,
    };
    final byteData = instanceManager.channel.codec.encodeMethodCall(
      MethodCall('onAdEvent', arguments),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'plugins.flutter.io/google_mobile_ads',
      byteData,
      (ByteData? data) {},
    );
    await pumpEventQueue();
  }

  setUp(() async {
    mockRemoteConfig = MockRemoteConfigService();
    channelCalls = <MethodCall>[];
    lastLoadedInterstitialAdId = null;
    lastLoadedRewardedAdId = null;
    adService = AdService();

    SharedPreferences.setMockInitialValues({});
    await AgeGateService.loadCached();

    dotenv.loadFromString(
      envString:
          'ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-3940256099942544/1033173712\n'
          'ADMOB_REWARDED_ANDROID=ca-app-pub-3940256099942544/5224354917\n'
          'ADMOB_INTERSTITIAL_IOS=ca-app-pub-3940256099942544/4411468910\n'
          'ADMOB_REWARDED_IOS=ca-app-pub-3940256099942544/1712485313\n',
      isOptional: true,
    );

    when(() => mockRemoteConfig.adFrequencyMultiplier).thenReturn(1.0);
    when(() => mockRemoteConfig.interstitialCooldownMinutes).thenReturn(3);

    if (di.sl.isRegistered<RemoteConfigService>()) {
      di.sl.unregister<RemoteConfigService>();
    }
    di.sl.registerLazySingleton<RemoteConfigService>(() => mockRemoteConfig);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (MethodCall call) async {
      channelCalls.add(call);
      if (call.method == 'MobileAds#initialize') {
        return InitializationStatus({});
      }
      if (call.method == 'MobileAds#updateRequestConfiguration') {
        return null;
      }
      if (call.method == 'loadInterstitialAd') {
        lastLoadedInterstitialAdId = call.arguments['adId'] as int;
        return null;
      }
      if (call.method == 'loadRewardedAd') {
        lastLoadedRewardedAdId = call.arguments['adId'] as int;
        return null;
      }
      if (call.method == 'setImmersiveMode' ||
          call.method == 'showAdWithoutView' ||
          call.method == 'disposeAd') {
        return null;
      }
      return null;
    });
  });

  tearDown(() {
    adService.dispose();
    if (di.sl.isRegistered<RemoteConfigService>()) {
      di.sl.unregister<RemoteConfigService>();
    }
  });

  // ===========================================================================
  // GROUP 1: Ad Frequency, Level Counter & Remote Config Modulation
  // ===========================================================================
  group('1. Ad Frequency & Counter Management', () {
    test('levelsPerInterstitial defaults to 3 when RemoteConfig is missing', () {
      di.sl.unregister<RemoteConfigService>();
      expect(AdService.levelsPerInterstitial, equals(3));
    });

    test('levelsPerInterstitial adapts to RemoteConfig multiplier', () {
      when(() => mockRemoteConfig.adFrequencyMultiplier).thenReturn(2.0);
      expect(AdService.levelsPerInterstitial, equals(2));

      when(() => mockRemoteConfig.adFrequencyMultiplier).thenReturn(0.5);
      expect(AdService.levelsPerInterstitial, equals(6));

      // Non-positive multiplier fallback
      when(() => mockRemoteConfig.adFrequencyMultiplier).thenReturn(0.0);
      expect(AdService.levelsPerInterstitial, equals(3));

      when(() => mockRemoteConfig.adFrequencyMultiplier).thenReturn(-1.0);
      expect(AdService.levelsPerInterstitial, equals(3));

      // Clamping limits (1 to 10)
      when(() => mockRemoteConfig.adFrequencyMultiplier).thenReturn(10.0);
      expect(AdService.levelsPerInterstitial, equals(1));

      when(() => mockRemoteConfig.adFrequencyMultiplier).thenReturn(0.1);
      expect(AdService.levelsPerInterstitial, equals(10));
    });

    test('interstitialCooldownMinutes defaults to 3 and reads RemoteConfig', () {
      di.sl.unregister<RemoteConfigService>();
      expect(AdService.interstitialCooldownMinutes, equals(3));

      di.sl.registerLazySingleton<RemoteConfigService>(() => mockRemoteConfig);
      when(() => mockRemoteConfig.interstitialCooldownMinutes).thenReturn(5);
      expect(AdService.interstitialCooldownMinutes, equals(5));
    });

    test('recordLevelCompletion increments counter and checks threshold', () {
      when(() => mockRemoteConfig.adFrequencyMultiplier).thenReturn(1.0); // 3 levels

      expect(adService.recordLevelCompletion(), isFalse); // Level 1
      expect(adService.recordLevelCompletion(), isFalse); // Level 2
      expect(adService.recordLevelCompletion(), isTrue);  // Level 3 (threshold reached)
      expect(adService.recordLevelCompletion(), isTrue);  // Level 4 (exceeded)
    });
  });

  // ===========================================================================
  // GROUP 2: Initialization, Request Configuration & Age Gate Integration
  // ===========================================================================
  group('2. Initialization & Age Gate Configuration', () {
    test('init() initializes MobileAds SDK and applies RequestConfiguration', () async {
      await adService.init();

      expect(channelCalls.any((c) => c.method == 'MobileAds#initialize'), isTrue);
      expect(
        channelCalls.any((c) => c.method == 'MobileAds#updateRequestConfiguration'),
        isTrue,
      );

      // Subsequent call is a no-op
      final initialCount = channelCalls.length;
      await adService.init();
      expect(channelCalls.length, equals(initialCount));
    });

    test('refreshAdConfig updates configuration mid-session for adult', () async {
      await adService.init();

      // Complete age gate as adult
      await AgeGateService.completeAgeGate(isAdult: true);
      adService.refreshAdConfig();

      final updateCalls = channelCalls
          .where((c) => c.method == 'MobileAds#updateRequestConfiguration')
          .toList();
      expect(updateCalls.length, greaterThanOrEqualTo(2));
      final lastUpdate = updateCalls.last;
      expect(
        lastUpdate.arguments['ageRestrictedTreatment'],
        equals(AgeRestrictedTreatment.unspecified.index),
      );
    });

    test('refreshAdConfig configures child restriction for minor', () async {
      await adService.init();

      // Set age gate as minor (under 16)
      await AgeGateService.completeAgeGate(isAdult: false);
      adService.refreshAdConfig();

      final updateCalls = channelCalls
          .where((c) => c.method == 'MobileAds#updateRequestConfiguration')
          .toList();
      final lastUpdate = updateCalls.last;
      expect(
        lastUpdate.arguments['ageRestrictedTreatment'],
        equals(AgeRestrictedTreatment.child.index),
      );
    });
  });

  // ===========================================================================
  // GROUP 3: Interstitial Ad Loading & Retry Lifecycle
  // ===========================================================================
  group('3. Interstitial Ad Loading & Retries', () {
    test('loadInterstitialAd requests ad from platform', () {
      adService.loadInterstitialAd();

      expect(lastLoadedInterstitialAdId, isNotNull);
      expect(channelCalls.any((c) => c.method == 'loadInterstitialAd'), isTrue);
    });

    test('successful load marks ad as immersive', () async {
      adService.loadInterstitialAd();
      expect(lastLoadedInterstitialAdId, isNotNull);

      await simulateAdEvent(lastLoadedInterstitialAdId!, 'onAdLoaded', {'responseInfo': null});

      expect(
        channelCalls.any(
          (c) =>
              c.method == 'setImmersiveMode' &&
              c.arguments['adId'] == lastLoadedInterstitialAdId &&
              c.arguments['immersiveModeEnabled'] == true,
        ),
        isTrue,
      );
    });

    test('load failure handles error gracefully and halts on dispose', () async {
      adService.loadInterstitialAd();
      expect(lastLoadedInterstitialAdId, isNotNull);

      final error = LoadAdError(1, 'com.google.android.gms.ads', 'Network Error', null);
      await simulateAdEvent(
        lastLoadedInterstitialAdId!,
        'onAdFailedToLoad',
        {'loadAdError': error},
      );

      // Verify no crash and ad dismissed safely on show
      var dismissed = false;
      adService.showInterstitialAd(
        isPremium: false,
        onDismissed: () => dismissed = true,
      );
      expect(dismissed, isTrue);
    });

    test('ad loaded after disposal is immediately discarded', () async {
      adService.loadInterstitialAd();
      final adId = lastLoadedInterstitialAdId!;

      adService.dispose();

      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});
      expect(
        channelCalls.any(
          (c) => c.method == 'disposeAd' && c.arguments['adId'] == adId,
        ),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // GROUP 4: Interstitial Ad Presentation & Dismissal Flow
  // ===========================================================================
  group('4. Interstitial Ad Presentation Flow', () {
    test('premium users bypass interstitial ads immediately', () {
      var dismissed = false;

      adService.showInterstitialAd(
        isPremium: true,
        onDismissed: () => dismissed = true,
      );

      expect(dismissed, isTrue);
      expect(channelCalls.any((c) => c.method == 'showAdWithoutView'), isFalse);
    });

    test('frequency gate skips ad when level threshold is not reached', () {
      var dismissed = false;

      // Only 1 level completed (threshold is 3)
      adService.recordLevelCompletion();

      adService.showInterstitialAd(
        isPremium: false,
        onDismissed: () => dismissed = true,
      );

      expect(dismissed, isTrue);
      expect(channelCalls.any((c) => c.method == 'showAdWithoutView'), isFalse);
    });

    test('force flag bypasses frequency gate', () async {
      adService.loadInterstitialAd();
      final adId = lastLoadedInterstitialAdId!;
      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});

      var dismissed = false;
      // 0 levels completed, but force: true
      adService.showInterstitialAd(
        isPremium: false,
        force: true,
        onDismissed: () => dismissed = true,
      );

      expect(
        channelCalls.any(
          (c) => c.method == 'showAdWithoutView' && c.arguments['adId'] == adId,
        ),
        isTrue,
      );
      expect(dismissed, isFalse);

      await simulateAdEvent(adId, 'onAdDismissedFullScreenContent');
      expect(dismissed, isTrue);
    });

    test('availability gate calls onDismissed when ad is not loaded', () {
      var dismissed = false;

      adService.recordLevelCompletion();
      adService.recordLevelCompletion();
      adService.recordLevelCompletion();

      adService.showInterstitialAd(
        isPremium: false,
        onDismissed: () => dismissed = true,
      );

      expect(dismissed, isTrue);
      expect(channelCalls.any((c) => c.method == 'showAdWithoutView'), isFalse);
    });

    test('full show and dismiss cycle resets completed levels counter', () async {
      adService.loadInterstitialAd();
      final adId = lastLoadedInterstitialAdId!;
      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});

      adService.recordLevelCompletion();
      adService.recordLevelCompletion();
      adService.recordLevelCompletion();

      var dismissed = false;
      adService.showInterstitialAd(
        isPremium: false,
        onDismissed: () => dismissed = true,
      );

      expect(dismissed, isFalse);
      await simulateAdEvent(adId, 'onAdDismissedFullScreenContent');
      expect(dismissed, isTrue);

      // Verify counter was reset to 0: next recordLevelCompletion starts at 1
      expect(adService.recordLevelCompletion(), isFalse);
    });

    test('cooldown gate prevents back-to-back ads within cooldown window', () async {
      when(() => mockRemoteConfig.interstitialCooldownMinutes).thenReturn(10);

      adService.loadInterstitialAd();
      final adId = lastLoadedInterstitialAdId!;
      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});

      adService.recordLevelCompletion();
      adService.recordLevelCompletion();
      adService.recordLevelCompletion();

      var firstDismissed = false;
      adService.showInterstitialAd(
        isPremium: false,
        onDismissed: () => firstDismissed = true,
      );
      await simulateAdEvent(adId, 'onAdDismissedFullScreenContent');
      expect(firstDismissed, isTrue);

      // Load second ad
      adService.loadInterstitialAd();
      final secondAdId = lastLoadedInterstitialAdId!;
      await simulateAdEvent(secondAdId, 'onAdLoaded', {'responseInfo': null});

      // Complete 3 more levels
      adService.recordLevelCompletion();
      adService.recordLevelCompletion();
      adService.recordLevelCompletion();

      var secondDismissed = false;
      channelCalls.clear();
      // Should be blocked by cooldown gate
      adService.showInterstitialAd(
        isPremium: false,
        onDismissed: () => secondDismissed = true,
      );

      expect(secondDismissed, isTrue);
      expect(channelCalls.any((c) => c.method == 'showAdWithoutView'), isFalse);
    });

    test('failure to show invokes onDismissed and disposes ad', () async {
      adService.loadInterstitialAd();
      final adId = lastLoadedInterstitialAdId!;
      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});

      adService.recordLevelCompletion();
      adService.recordLevelCompletion();
      adService.recordLevelCompletion();

      var dismissed = false;
      adService.showInterstitialAd(
        isPremium: false,
        onDismissed: () => dismissed = true,
      );

      final error = AdError(1, 'com.google.android.gms.ads', 'Display Error');
      await simulateAdEvent(
        adId,
        'onFailedToShowFullScreenContent',
        {'error': error},
      );

      expect(dismissed, isTrue);
      expect(
        channelCalls.any(
          (c) => c.method == 'disposeAd' && c.arguments['adId'] == adId,
        ),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // GROUP 5: Rewarded Ad Loading & State Caching
  // ===========================================================================
  group('5. Rewarded Ad Loading & State', () {
    test('isRewardedAdLoaded reflects cache presence', () async {
      expect(adService.isRewardedAdLoaded, isFalse);

      adService.loadRewardedAd();
      expect(lastLoadedRewardedAdId, isNotNull);
      final adId = lastLoadedRewardedAdId!;

      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});
      expect(adService.isRewardedAdLoaded, isTrue);
    });

    test('loadRewardedAd prevents duplicate in-flight loads', () {
      adService.loadRewardedAd();
      final countAfterFirst = channelCalls.where((c) => c.method == 'loadRewardedAd').length;

      // Duplicate load while first is in flight
      adService.loadRewardedAd();
      final countAfterSecond = channelCalls.where((c) => c.method == 'loadRewardedAd').length;

      expect(countAfterSecond, equals(countAfterFirst));
    });

    test('load failure clears in-flight state and keeps isRewardedAdLoaded false', () async {
      adService.loadRewardedAd();
      final adId = lastLoadedRewardedAdId!;

      final error = LoadAdError(1, 'com.google.android.gms.ads', 'Ad unavailable', null);
      await simulateAdEvent(adId, 'onAdFailedToLoad', {'loadAdError': error});

      expect(adService.isRewardedAdLoaded, isFalse);
    });

    test('rewarded ad loaded after disposal is immediately discarded', () async {
      adService.loadRewardedAd();
      final adId = lastLoadedRewardedAdId!;

      adService.dispose();

      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});
      expect(
        channelCalls.any(
          (c) => c.method == 'disposeAd' && c.arguments['adId'] == adId,
        ),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // GROUP 6: Rewarded Ad Presentation, Rewards & Hint Wrapper
  // ===========================================================================
  group('6. Rewarded Ad Presentation & Reward Delivery', () {
    test('premium users immediately receive reward without ad display', () {
      RewardItem? earnedReward;
      var dismissed = false;

      adService.showRewardedAd(
        isPremium: true,
        onUserEarnedReward: (reward) => earnedReward = reward,
        onDismissed: () => dismissed = true,
      );

      expect(earnedReward, isNotNull);
      expect(earnedReward!.type, equals('Premium Reward'));
      expect(earnedReward!.amount, equals(1));
      expect(dismissed, isTrue);
      expect(channelCalls.any((c) => c.method == 'showAdWithoutView'), isFalse);
    });

    testWidgets('unloaded rewarded ad triggers snackbar when context is provided', (tester) async {
      RewardItem? earnedReward;
      var dismissed = false;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      adService.showRewardedAd(
                        context: context,
                        isPremium: false,
                        onUserEarnedReward: (reward) => earnedReward = reward,
                        onDismissed: () => dismissed = true,
                      );
                    },
                    child: const Text('Show Rewarded'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Rewarded'));
      await tester.pump();

      expect(earnedReward, isNull);
      expect(dismissed, isTrue);
      expect(
        find.text('Ad is not ready yet. Please wait a few seconds and try again.'),
        findsOneWidget,
      );
    });

    test('full rewarded ad cycle delivers reward and triggers dismiss', () async {
      adService.loadRewardedAd();
      final adId = lastLoadedRewardedAdId!;
      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});

      RewardItem? earnedReward;
      var dismissed = false;

      adService.showRewardedAd(
        isPremium: false,
        onUserEarnedReward: (reward) => earnedReward = reward,
        onDismissed: () => dismissed = true,
      );

      expect(
        channelCalls.any(
          (c) => c.method == 'showAdWithoutView' && c.arguments['adId'] == adId,
        ),
        isTrue,
      );

      // Simulate reward earned event
      final reward = RewardItem(50, 'Coins');
      await simulateAdEvent(adId, 'onRewardedAdUserEarnedReward', {'rewardItem': reward});
      expect(earnedReward, isNotNull);
      expect(earnedReward!.amount, equals(50));
      expect(earnedReward!.type, equals('Coins'));

      // Simulate dismiss
      await simulateAdEvent(adId, 'onAdDismissedFullScreenContent');
      expect(dismissed, isTrue);
      expect(adService.isRewardedAdLoaded, isFalse);
    });

    test('failed to show rewarded ad invokes onDismissed', () async {
      adService.loadRewardedAd();
      final adId = lastLoadedRewardedAdId!;
      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});

      RewardItem? earnedReward;
      var dismissed = false;

      adService.showRewardedAd(
        isPremium: false,
        onUserEarnedReward: (reward) => earnedReward = reward,
        onDismissed: () => dismissed = true,
      );

      final error = AdError(1, 'com.google.android.gms.ads', 'Video playback error');
      await simulateAdEvent(adId, 'onFailedToShowFullScreenContent', {'error': error});

      expect(earnedReward, isNull);
      expect(dismissed, isTrue);
    });

    test('showHintRewardedAd convenience wrapper delivers hint callback', () async {
      adService.loadRewardedAd();
      final adId = lastLoadedRewardedAdId!;
      await simulateAdEvent(adId, 'onAdLoaded', {'responseInfo': null});

      var hintEarned = false;
      var dismissed = false;

      adService.showHintRewardedAd(
        isPremium: false,
        onHintEarned: () => hintEarned = true,
        onDismissed: () => dismissed = true,
      );

      final reward = RewardItem(1, 'Hint');
      await simulateAdEvent(adId, 'onRewardedAdUserEarnedReward', {'rewardItem': reward});
      expect(hintEarned, isTrue);

      await simulateAdEvent(adId, 'onAdDismissedFullScreenContent');
      expect(dismissed, isTrue);
    });
  });

  // ===========================================================================
  // GROUP 7: COPPA / Child-Safe Rewarded Flow
  // ===========================================================================
  group('7. COPPA & Child-Safe Mode', () {
    test('childSafe flag in adult session flushes personalized ad and reloads child-safe', () async {
      await AgeGateService.completeAgeGate(isAdult: true);

      adService.loadRewardedAd();
      final originalAdId = lastLoadedRewardedAdId!;
      await simulateAdEvent(originalAdId, 'onAdLoaded', {'responseInfo': null});
      expect(adService.isRewardedAdLoaded, isTrue);

      RewardItem? earnedReward;
      var dismissed = false;

      // Adult requesting child-safe ad (e.g. entering Kids Zone)
      adService.showRewardedAd(
        isPremium: false,
        childSafe: true,
        onUserEarnedReward: (reward) => earnedReward = reward,
        onDismissed: () => dismissed = true,
      );

      // Verify original ad was disposed for COPPA compliance
      expect(
        channelCalls.any(
          (c) => c.method == 'disposeAd' && c.arguments['adId'] == originalAdId,
        ),
        isTrue,
      );

      // Verify a fresh child-safe ad was requested
      final childSafeAdId = lastLoadedRewardedAdId!;
      expect(childSafeAdId, isNot(equals(originalAdId)));

      // Simulate child-safe load and show
      await simulateAdEvent(childSafeAdId, 'onAdLoaded', {'responseInfo': null});
      expect(
        channelCalls.any(
          (c) => c.method == 'showAdWithoutView' && c.arguments['adId'] == childSafeAdId,
        ),
        isTrue,
      );

      final reward = RewardItem(10, 'Stars');
      await simulateAdEvent(childSafeAdId, 'onRewardedAdUserEarnedReward', {'rewardItem': reward});
      expect(earnedReward, isNotNull);
      expect(earnedReward!.amount, equals(10));
      expect(earnedReward!.type, equals('Stars'));

      await simulateAdEvent(childSafeAdId, 'onAdDismissedFullScreenContent');
      expect(dismissed, isTrue);
    });
  });

  // ===========================================================================
  // GROUP 8: Teardown & Resource Disposal
  // ===========================================================================
  group('8. Teardown & Resource Disposal', () {
    test('dispose() cleans up platform interstitial and rewarded ads', () async {
      adService.loadInterstitialAd();
      final interstitialId = lastLoadedInterstitialAdId!;
      await simulateAdEvent(interstitialId, 'onAdLoaded', {'responseInfo': null});

      adService.loadRewardedAd();
      final rewardedId = lastLoadedRewardedAdId!;
      await simulateAdEvent(rewardedId, 'onAdLoaded', {'responseInfo': null});

      expect(adService.isRewardedAdLoaded, isTrue);

      channelCalls.clear();
      adService.dispose();

      expect(adService.isRewardedAdLoaded, isFalse);
      expect(
        channelCalls.any(
          (c) => c.method == 'disposeAd' && c.arguments['adId'] == interstitialId,
        ),
        isTrue,
      );
      expect(
        channelCalls.any(
          (c) => c.method == 'disposeAd' && c.arguments['adId'] == rewardedId,
        ),
        isTrue,
      );
    });

    test('post-disposal operations are safely ignored', () async {
      adService.dispose();

      channelCalls.clear();
      await adService.init();
      expect(channelCalls.isEmpty, isTrue);

      adService.refreshAdConfig();
      expect(channelCalls.isEmpty, isTrue);
    });
  });
}
