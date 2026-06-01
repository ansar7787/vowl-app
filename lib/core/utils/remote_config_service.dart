import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Abstract contract defining the Remote Configuration service interface.
///
/// Decouples remote config parameters from Firebase SDK concrete dependencies,
/// satisfying the SOLID Dependency Inversion Principle (DIP).
abstract class RemoteConfigService {
  /// Factory mapping constructor supporting seamless backwards compatibility for callers.
  factory RemoteConfigService(FirebaseRemoteConfig remoteConfig) = FirebaseRemoteConfigService;

  /// Initializes default values and triggers remote fetch/activation sequences.
  Future<void> init();

  /// Gets the ad presentation frequency multiplier.
  double get adFrequencyMultiplier;

  /// Determines if three-fold coin/experience multipliers are activated.
  bool get tripleRewardsEnabled;

  /// Gets the minimum client application version required to run.
  String get minAppVersion;

  /// Gets the standard coins rewarded per quest victory.
  int get coinsPerVictory;

  /// Gets the kids-zone coins rewarded per quest victory.
  int get kidsCoinsPerVictory;

  /// Gets the difficulty modifier applied to level quest engines.
  double get levelDifficultyModifier;
}

/// Concrete implementation of [RemoteConfigService] integrated with Firebase Remote Config.
class FirebaseRemoteConfigService implements RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  // Configuration key constants to prevent typos and ensure maintainability
  static const String keyAdFrequencyMultiplier = 'ad_frequency_multiplier';
  static const String keyTripleRewardsEnabled = 'triple_rewards_enabled';
  static const String keyMinAppVersion = 'min_app_version';
  static const String keyLevelDifficultyModifier = 'level_difficulty_modifier';
  static const String keyCoinsPerVictory = 'coins_per_victory';
  static const String keyKidsCoinsPerVictory = 'kids_coins_per_victory';

  FirebaseRemoteConfigService(this._remoteConfig);

  @override
  Future<void> init() async {
    try {
      // 1. Establish offline local fallback defaults
      await _remoteConfig.setDefaults(const {
        keyAdFrequencyMultiplier: 1.0,
        keyTripleRewardsEnabled: true,
        keyMinAppVersion: '1.0.0',
        keyLevelDifficultyModifier: 1.0,
        keyCoinsPerVictory: 10,
        keyKidsCoinsPerVictory: 5,
      });

      // 2. Configure fetch settings (instantly flush caches in local dev mode)
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // 3. Fetch and activate values from Google Remote servers
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('RemoteConfigService: Local config initialization completed. Remote fetch bypassed: $e');
    }
  }

  @override
  double get adFrequencyMultiplier => _remoteConfig.getDouble(keyAdFrequencyMultiplier);

  @override
  bool get tripleRewardsEnabled => _remoteConfig.getBool(keyTripleRewardsEnabled);

  @override
  String get minAppVersion => _remoteConfig.getString(keyMinAppVersion);

  @override
  int get coinsPerVictory => _remoteConfig.getInt(keyCoinsPerVictory);

  @override
  int get kidsCoinsPerVictory => _remoteConfig.getInt(keyKidsCoinsPerVictory);

  @override
  double get levelDifficultyModifier => _remoteConfig.getDouble(keyLevelDifficultyModifier);
}
