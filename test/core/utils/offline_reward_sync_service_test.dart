import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/offline_reward_sync_service.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNetworkInfo mockNetworkInfo;
  late MockGamificationRepository mockGamificationRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    mockNetworkInfo = MockNetworkInfo();
    mockGamificationRepository = MockGamificationRepository();

    if (di.sl.isRegistered<NetworkInfo>()) {
      di.sl.unregister<NetworkInfo>();
    }
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);

    if (di.sl.isRegistered<GamificationRepository>()) {
      di.sl.unregister<GamificationRepository>();
    }
    di.sl.registerSingleton<GamificationRepository>(mockGamificationRepository);

    final service = OfflineRewardSyncService.instance;
    await service.init(prefs);
    await service.clearQueue();
  });

  tearDown(() {
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
    if (di.sl.isRegistered<GamificationRepository>()) {
      di.sl.unregister<GamificationRepository>();
    }
  });

  group('OfflineRewardSyncService', () {
    test('init loads empty queue when no saved data', () {
      final service = OfflineRewardSyncService.instance;
      expect(service.pendingCount, 0);
      expect(service.totalPendingCoins, 0);
      expect(service.totalPendingXp, 0);
    });

    test('recordPendingReward queues reward and persists to disk', () async {
      final service = OfflineRewardSyncService.instance;

      await service.recordPendingReward(
        gameType: 'vocabulary',
        level: 1,
        xp: 15,
        coins: 10,
        stars: 3,
      );

      expect(service.pendingCount, 1);
      expect(service.totalPendingCoins, 10);
      expect(service.totalPendingXp, 15);

      await service.recordPendingReward(
        gameType: 'reading',
        level: 2,
        xp: 20,
        coins: 15,
        stars: 2,
      );

      expect(service.pendingCount, 2);
      expect(service.totalPendingCoins, 25);
      expect(service.totalPendingXp, 35);
    });

    test('re-recording same gameType and level replaces without duplicating', () async {
      final service = OfflineRewardSyncService.instance;

      await service.recordPendingReward(
        gameType: 'vocabulary',
        level: 1,
        xp: 10,
        coins: 5,
        stars: 1,
      );

      await service.recordPendingReward(
        gameType: 'vocabulary',
        level: 1,
        xp: 15,
        coins: 10,
        stars: 3,
      );

      expect(service.pendingCount, 1);
      expect(service.totalPendingCoins, 10);
      expect(service.totalPendingXp, 15);
    });

    test('syncPendingRewards skips when device is offline', () async {
      final service = OfflineRewardSyncService.instance;

      when(() => mockNetworkInfo.isCurrentlyOffline).thenReturn(true);

      await service.recordPendingReward(
        gameType: 'speaking',
        level: 1,
        xp: 15,
        coins: 10,
        stars: 3,
      );

      await service.syncPendingRewards();

      expect(service.pendingCount, 1);
      verifyNever(
        () => mockGamificationRepository.updateUserRewards(
          gameType: any(named: 'gameType'),
          level: any(named: 'level'),
          xpIncrease: any(named: 'xpIncrease'),
          coinIncrease: any(named: 'coinIncrease'),
          starsEarned: any(named: 'starsEarned'),
        ),
      );
    });

    test('syncPendingRewards flushes rewards when online and updates queue', () async {
      final service = OfflineRewardSyncService.instance;

      when(() => mockNetworkInfo.isCurrentlyOffline).thenReturn(false);
      when(
        () => mockGamificationRepository.updateUserRewards(
          gameType: any(named: 'gameType'),
          level: any(named: 'level'),
          xpIncrease: any(named: 'xpIncrease'),
          coinIncrease: any(named: 'coinIncrease'),
          starsEarned: any(named: 'starsEarned'),
          isVaultReward: any(named: 'isVaultReward'),
          claimChestTier: any(named: 'claimChestTier'),
          addMagicStars: any(named: 'addMagicStars'),
        ),
      ).thenAnswer((_) async => const Right(null));

      await service.recordPendingReward(
        gameType: 'writing',
        level: 3,
        xp: 25,
        coins: 12,
        stars: 3,
      );

      await service.syncPendingRewards();

      expect(service.pendingCount, 0);
      expect(service.totalPendingCoins, 0);
      expect(service.totalPendingXp, 0);
    });

    test('vault reward does not overwrite normal level 1 in queue', () async {
      final service = OfflineRewardSyncService.instance;

      await service.recordPendingReward(
        gameType: 'vocabulary',
        level: 1,
        xp: 15,
        coins: 10,
        stars: 3,
      );

      await service.recordPendingReward(
        gameType: 'vocabulary',
        level: 1,
        xp: 0,
        coins: 50,
        stars: 0,
        isVaultReward: true,
        claimChestTier: 1,
      );

      expect(service.pendingCount, 2);
      expect(service.totalPendingCoins, 60);
      expect(service.totalPendingXp, 15);
    });
  });
}
