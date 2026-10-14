import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/offline_play_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflinePlayGateService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = OfflinePlayGateService.instance;
    service.resetQuotaAfterAd();
  });

  tearDown(() {
    service.resetQuotaAfterAd();
  });

  group('OfflinePlayGateService - Initial State & Defaults', () {
    test('declares expected business rules and constant values', () {
      expect(OfflinePlayGateService.maxOfflineLevels, equals(3));
    });

    test('initializes with clean zero state', () {
      expect(service.offlineLevelsPlayed, equals(0));
      expect(service.remainingOfflinePlays, equals(3));
      expect(service.isOfflineQuotaExhausted, isFalse);
      expect(service.hasPendingReconnectReset, isFalse);
    });
  });

  group('OfflinePlayGateService - Quota Progression', () {
    test('increments counter and decreases remaining plays on recordOfflineLevel', () {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      final firstExhausted = service.recordOfflineLevel();
      expect(firstExhausted, isFalse);
      expect(service.offlineLevelsPlayed, equals(1));
      expect(service.remainingOfflinePlays, equals(2));
      expect(service.isOfflineQuotaExhausted, isFalse);
      expect(notifyCount, equals(1));

      final secondExhausted = service.recordOfflineLevel();
      expect(secondExhausted, isFalse);
      expect(service.offlineLevelsPlayed, equals(2));
      expect(service.remainingOfflinePlays, equals(1));
      expect(service.isOfflineQuotaExhausted, isFalse);
      expect(notifyCount, equals(2));

      final thirdExhausted = service.recordOfflineLevel();
      expect(thirdExhausted, isTrue);
      expect(service.offlineLevelsPlayed, equals(3));
      expect(service.remainingOfflinePlays, equals(0));
      expect(service.isOfflineQuotaExhausted, isTrue);
      expect(notifyCount, equals(3));
    });
  });

  group('OfflinePlayGateService - Reconnection & Pending Ad Reset', () {
    test('markReconnected sets pending flag only when levels were played offline', () {
      // 0 plays -> no pending reset
      service.markReconnected();
      expect(service.hasPendingReconnectReset, isFalse);

      // Played 1 level -> mark reconnected triggers pending flag
      service.recordOfflineLevel();
      service.markReconnected();
      expect(service.hasPendingReconnectReset, isTrue);
    });
  });

  group('OfflinePlayGateService - Quota Reset After Ad', () {
    test('resetQuotaAfterAd restores full quota and clears pending flags', () {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      // Exhaust quota
      service.recordOfflineLevel();
      service.recordOfflineLevel();
      service.recordOfflineLevel();
      service.markReconnected();
      expect(service.isOfflineQuotaExhausted, isTrue);
      expect(service.hasPendingReconnectReset, isTrue);

      // Reset after ad
      service.resetQuotaAfterAd();

      expect(service.offlineLevelsPlayed, equals(0));
      expect(service.remainingOfflinePlays, equals(3));
      expect(service.isOfflineQuotaExhausted, isFalse);
      expect(service.hasPendingReconnectReset, isFalse);
      expect(notifyCount, greaterThan(3));
    });
  });

  group('OfflinePlayGateService - Rewarded Bonus Plays', () {
    test('grantBonusOfflinePlays gives 3 additional plays after watching rewarded ad', () {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      // Exhaust quota
      service.recordOfflineLevel();
      service.recordOfflineLevel();
      service.recordOfflineLevel();
      expect(service.isOfflineQuotaExhausted, isTrue);

      // Grant rewarded bonus
      service.grantBonusOfflinePlays();

      expect(service.offlineLevelsPlayed, equals(0));
      expect(service.remainingOfflinePlays, equals(3));
      expect(service.isOfflineQuotaExhausted, isFalse);
      expect(notifyCount, greaterThan(3));
    });
  });

  group('OfflinePlayGateService - Persistence & 24h Expiration', () {
    test('init restores persisted count when timestamp is within 24 hours', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'offline_levels_played': 2,
        'offline_levels_timestamp': now - const Duration(hours: 4).inMilliseconds,
      });

      await service.init();

      expect(service.offlineLevelsPlayed, equals(2));
      expect(service.remainingOfflinePlays, equals(1));
      expect(service.isOfflineQuotaExhausted, isFalse);
    });

    test('init auto-resets stale quota when timestamp is older than 24 hours', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'offline_levels_played': 3,
        'offline_levels_timestamp': now - const Duration(hours: 25).inMilliseconds,
      });

      await service.init();

      expect(service.offlineLevelsPlayed, equals(0));
      expect(service.remainingOfflinePlays, equals(3));
      expect(service.isOfflineQuotaExhausted, isFalse);
    });
  });
}

