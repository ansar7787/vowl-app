import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';
import 'package:vowl/features/referral/domain/repositories/referral_repository.dart';
import 'package:vowl/features/referral/presentation/bloc/referral_cubit.dart';

class FakeReferralRepository implements ReferralRepository {
  String returnedCode = 'VOWL-TEST';
  int syncedCount = 0;
  List<AmbassadorLeaderboardItem> leaderboard = [];
  ReferralClaimResult claimResult = ReferralClaimResult.success(
    coinsAwarded: 100,
    vipDaysAwarded: 1,
    referrerName: 'Alice',
  );
  AmbassadorRewardClaimResult cupResult = AmbassadorRewardClaimResult.success(
    rank: 1,
    coinsAwarded: 0,
    vipDaysAwarded: 30,
    monthKey: '2026-10',
  );

  @override
  Future<String> getOrCreateReferralCode(UserEntity user) async => returnedCode;

  @override
  Future<int> syncAmbassadorRewards(UserEntity user) async => syncedCount;

  @override
  Future<List<AmbassadorLeaderboardItem>> getMonthlyAmbassadorLeaderboard({
    String? monthKey,
  }) async => leaderboard;

  @override
  Future<ReferralClaimResult> claimReferralCode({
    required String code,
    required UserEntity user,
  }) async => claimResult;

  @override
  Future<AmbassadorRewardClaimResult> claimMonthlyAmbassadorReward({
    required UserEntity user,
  }) async => cupResult;

  @override
  Future<void> onFriendCompletedLevelOne({
    required String friendUserId,
    required String referrerCode,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeReferralRepository fakeRepo;
  late ReferralCubit cubit;
  const testUser = UserEntity(
    id: 'user_123',
    email: 'test@example.com',
    displayName: 'Test User',
    totalReferralsCount: 2,
    monthlyReferralsCount: 1,
  );

  setUp(() {
    fakeRepo = FakeReferralRepository();
    cubit = ReferralCubit(repository: fakeRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('ReferralCubit', () {
    test('initial state has default values', () {
      expect(cubit.state.isLoading, false);
      expect(cubit.state.referralCode, isNull);
      expect(cubit.state.ambassadorLeaderboard, isEmpty);
    });

    test('init loads code, syncs rewards, and populates leaderboard', () async {
      fakeRepo.syncedCount = 2;
      fakeRepo.leaderboard = [
        const AmbassadorLeaderboardItem(
          userId: 'u1',
          displayName: 'Top Champ',
          referralCount: 50,
          rank: 1,
        ),
      ];

      await cubit.init(testUser);

      expect(cubit.state.isLoading, false);
      expect(cubit.state.referralCode, 'VOWL-TEST');
      expect(cubit.state.syncedAmbassadorRewardCount, 2);
      expect(cubit.state.ambassadorLeaderboard.length, 1);
      expect(cubit.state.ambassadorLeaderboard.first.displayName, 'Top Champ');
    });

    test('claimCode emits success result', () async {
      await cubit.claimCode('VOWL-ALICE', testUser);

      expect(cubit.state.isClaiming, false);
      expect(cubit.state.claimSuccess, isNotNull);
      expect(cubit.state.claimSuccess!.referrerName, 'Alice');
      expect(cubit.state.claimError, isNull);
    });

    test('claimMonthlyCupReward emits result', () async {
      await cubit.claimMonthlyCupReward(testUser);

      expect(cubit.state.isClaimingCupReward, false);
      expect(cubit.state.cupRewardClaimResult, isNotNull);
      expect(cubit.state.cupRewardClaimResult!.success, true);
      expect(cubit.state.cupRewardClaimResult!.rank, 1);
    });
  });
}
