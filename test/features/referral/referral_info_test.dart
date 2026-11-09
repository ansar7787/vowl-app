import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';

void main() {
  group('AmbassadorRewardTier', () {
    test('assigns gold tier to rank 1 (1 Month Free VIP)', () {
      const item = AmbassadorLeaderboardItem(
        userId: 'u1',
        displayName: 'Top Ambassador',
        referralCount: 42,
        rank: 1,
      );
      expect(item.rewardTier, AmbassadorRewardTier.gold);
      expect(item.rewardTier.vipDays, 30);
      expect(item.rewardTier.coins, 0);
    });

    test('assigns silver tier to rank 2 (1 Week Free VIP)', () {
      const item = AmbassadorLeaderboardItem(
        userId: 'u2',
        displayName: 'Second Place',
        referralCount: 28,
        rank: 2,
      );
      expect(item.rewardTier, AmbassadorRewardTier.silver);
      expect(item.rewardTier.vipDays, 7);
      expect(item.rewardTier.coins, 0);
    });

    test('assigns bronze tier to rank 3 (500 Coins + 3 Days VIP)', () {
      const item = AmbassadorLeaderboardItem(
        userId: 'u3',
        displayName: 'Third Place',
        referralCount: 19,
        rank: 3,
      );
      expect(item.rewardTier, AmbassadorRewardTier.bronze);
      expect(item.rewardTier.vipDays, 3);
      expect(item.rewardTier.coins, 500);
    });

    test('assigns topTen tier to ranks 4 through 10 (200 Coins)', () {
      for (var r = 4; r <= 10; r++) {
        final item = AmbassadorLeaderboardItem(
          userId: 'u$r',
          displayName: 'Player $r',
          referralCount: 15 - r,
          rank: r,
        );
        expect(item.rewardTier, AmbassadorRewardTier.topTen);
        expect(item.rewardTier.vipDays, 0);
        expect(item.rewardTier.coins, 200);
      }
    });

    test('assigns participant tier to rank 11+', () {
      const item = AmbassadorLeaderboardItem(
        userId: 'u11',
        displayName: 'Player 11',
        referralCount: 2,
        rank: 11,
      );
      expect(item.rewardTier, AmbassadorRewardTier.participant);
      expect(item.rewardTier.vipDays, 0);
      expect(item.rewardTier.coins, 0);
    });

    test(
      'strictly assigns none tier if referralCount is 0, even for top ranks',
      () {
        const rankOneZeroRef = AmbassadorLeaderboardItem(
          userId: 'u0',
          displayName: 'Zero Ref Player',
          referralCount: 0,
          rank: 1,
        );
        expect(rankOneZeroRef.rewardTier, AmbassadorRewardTier.none);
        expect(rankOneZeroRef.rewardTier.vipDays, 0);
        expect(rankOneZeroRef.rewardTier.coins, 0);

        const rankFiveZeroRef = AmbassadorLeaderboardItem(
          userId: 'u5',
          displayName: 'Zero Ref Top 10',
          referralCount: 0,
          rank: 5,
        );
        expect(rankFiveZeroRef.rewardTier, AmbassadorRewardTier.none);
        expect(rankFiveZeroRef.rewardTier.vipDays, 0);
        expect(rankFiveZeroRef.rewardTier.coins, 0);
      },
    );
  });

  group('ReferralClaimResult', () {
    test('success factory creates valid object', () {
      final res = ReferralClaimResult.success(
        coinsAwarded: 100,
        vipDaysAwarded: 1,
        referrerName: 'John',
      );
      expect(res.success, true);
      expect(res.isPending, false);
      expect(res.coinsAwarded, 100);
      expect(res.vipDaysAwarded, 1);
      expect(res.referrerName, 'John');
    });

    test('pending factory creates valid milestone pending object', () {
      final res = ReferralClaimResult.pending(referrerName: 'Alice');
      expect(res.success, true);
      expect(res.isPending, true);
      expect(res.coinsAwarded, 0);
      expect(res.vipDaysAwarded, 0);
      expect(res.referrerName, 'Alice');
      expect(res.message.contains('Adventure Level 1'), true);
    });

    test('failure factory creates valid object', () {
      final res = ReferralClaimResult.failure('Code already used');
      expect(res.success, false);
      expect(res.coinsAwarded, 0);
      expect(res.message, 'Code already used');
    });
  });

  group('AmbassadorRewardClaimResult', () {
    test('success factory creates valid object', () {
      final res = AmbassadorRewardClaimResult.success(
        rank: 1,
        coinsAwarded: 0,
        vipDaysAwarded: 30,
        monthKey: '2026-10',
      );
      expect(res.success, true);
      expect(res.rank, 1);
      expect(res.vipDaysAwarded, 30);
      expect(res.monthKey, '2026-10');
    });

    test('failure factory creates valid object', () {
      final res = AmbassadorRewardClaimResult.failure('Not ranked');
      expect(res.success, false);
      expect(res.message, 'Not ranked');
    });
  });
}
