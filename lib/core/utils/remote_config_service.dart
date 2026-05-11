import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  Future<void> init() async {
    try {
      await _remoteConfig.setDefaults({
        'ad_frequency_multiplier': 1.0,
        'triple_rewards_enabled': true,
        'min_app_version': '1.0.0',
        'level_difficulty_modifier': 1.0,
        'coins_per_victory': 10,
        'kids_coins_per_victory': 5,
      });

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Fallback if network fails
    }
  }

  // Getters for specific values
  double get adFrequencyMultiplier => _remoteConfig.getDouble('ad_frequency_multiplier');
  bool get tripleRewardsEnabled => _remoteConfig.getBool('triple_rewards_enabled');
  String get minAppVersion => _remoteConfig.getString('min_app_version');
  int get coinsPerVictory => _remoteConfig.getInt('coins_per_victory');
  int get kidsCoinsPerVictory => _remoteConfig.getInt('kids_coins_per_victory');
}
