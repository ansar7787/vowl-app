import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_update_service.dart';
import 'package:vowl/core/utils/remote_config_service.dart';

class MockRemoteConfigService implements RemoteConfigService {
  String mockMinVersion;
  String mockLatestVersion;
  String mockReleaseNotes;
  String mockStoreUrl;

  MockRemoteConfigService({
    this.mockMinVersion = '1.0.0',
    this.mockLatestVersion = '1.0.0',
    this.mockReleaseNotes = '',
    this.mockStoreUrl = '',
  });

  @override
  String get minAppVersion => mockMinVersion;

  @override
  String get latestAppVersion => mockLatestVersion;

  @override
  String get updateReleaseNotes => mockReleaseNotes;

  @override
  String get updateStoreUrl => mockStoreUrl;

  @override
  double get adFrequencyMultiplier => 1.0;

  @override
  int get coinsPerVictory => 10;

  @override
  int get dailyRewardLimit => 5;

  @override
  int get hintCoinCost => 15;

  @override
  Future<void> init() async {}

  @override
  int get interstitialCooldownMinutes => 3;

  @override
  bool get isRemoteDataFresh => true;

  @override
  int get kidsCoinsPerVictory => 5;

  @override
  double get levelDifficultyModifier => 1.0;

  @override
  bool get tripleRewardsEnabled => true;
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Vowl',
      packageName: 'com.vowl.app',
      version: '1.0.0',
      buildNumber: '3',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
  });

  group('AppUpdateServiceImpl', () {
    test('returns AppUpdateType.none when app version equals latest', () async {
      final mockConfig = MockRemoteConfigService(
        mockMinVersion: '1.0.0',
        mockLatestVersion: '1.0.0',
      );
      final service = AppUpdateServiceImpl(remoteConfig: mockConfig);

      final result = await service.checkForUpdate();
      expect(result.type, AppUpdateType.none);
      expect(result.hasUpdate, isFalse);
    });

    test('returns AppUpdateType.force when current version < minAppVersion', () async {
      final mockConfig = MockRemoteConfigService(
        mockMinVersion: '1.1.0',
        mockLatestVersion: '1.2.0',
        mockReleaseNotes: 'Security patch',
      );
      final service = AppUpdateServiceImpl(remoteConfig: mockConfig);

      final result = await service.checkForUpdate();
      expect(result.type, AppUpdateType.force);
      expect(result.isForced, isTrue);
      expect(result.hasUpdate, isTrue);
      expect(result.releaseNotes, 'Security patch');
    });

    test('returns AppUpdateType.flexible when latest > current and current >= min', () async {
      final mockConfig = MockRemoteConfigService(
        mockMinVersion: '1.0.0',
        mockLatestVersion: '1.0.5',
        mockReleaseNotes: 'Bug fixes',
      );
      final service = AppUpdateServiceImpl(remoteConfig: mockConfig);

      final result = await service.checkForUpdate();
      expect(result.type, AppUpdateType.flexible);
      expect(result.isFlexible, isTrue);
      expect(result.hasUpdate, isTrue);
      expect(result.releaseNotes, 'Bug fixes');
    });

    test('respects 24-hour frequency cap for flexible update when dismissed', () async {
      final mockConfig = MockRemoteConfigService(
        mockMinVersion: '1.0.0',
        mockLatestVersion: '1.0.5',
      );
      final service = AppUpdateServiceImpl(remoteConfig: mockConfig);

      // Record dismissal for 1.0.5
      await service.recordDismissal('1.0.5');

      // Subsequent check within 24h should return none
      final result = await service.checkForUpdate();
      expect(result.type, AppUpdateType.none);

      // But if ignoreFrequencyCap is true, returns flexible
      final forcedCheck = await service.checkForUpdate(ignoreFrequencyCap: true);
      expect(forcedCheck.type, AppUpdateType.flexible);
    });

    test('force update bypasses frequency capping', () async {
      final mockConfig = MockRemoteConfigService(
        mockMinVersion: '2.0.0',
        mockLatestVersion: '2.0.0',
      );
      final service = AppUpdateServiceImpl(remoteConfig: mockConfig);

      // Record dismissal for 2.0.0
      await service.recordDismissal('2.0.0');

      // Forced update must still trigger!
      final result = await service.checkForUpdate();
      expect(result.type, AppUpdateType.force);
      expect(result.isForced, isTrue);
    });
  });
}

