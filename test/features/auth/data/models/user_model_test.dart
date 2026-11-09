import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel displayName sanitization', () {
    test('preserves valid displayName', () {
      final model = UserModel.fromMap({
        'id': 'u1',
        'email': 'user@vowl.app',
        'displayName': 'John Doe',
      });
      expect(model.displayName, 'John Doe');
      expect(model.safeDisplayName, 'John Doe');
    });

    test('replaces "Unknown User" with clean name derived from email', () {
      final model = UserModel.fromMap({
        'id': 'u2',
        'email': 'susan.clark@vowl.app',
        'displayName': 'Unknown User',
      });
      expect(model.displayName, 'Susan Clark');
      expect(model.safeDisplayName, 'Susan Clark');
    });

    test(
      'replaces "unknown" case-insensitively with clean email derivation',
      () {
        final model = UserModel.fromMap({
          'id': 'u3',
          'email': 'peter_parker@marvel.com',
          'displayName': 'UNKNOWN',
        });
        expect(model.displayName, 'Peter Parker');
        expect(model.safeDisplayName, 'Peter Parker');
      },
    );

    test('replaces empty displayName with email derivation', () {
      final model = UserModel.fromMap({
        'id': 'u4',
        'email': 'tony.stark@avengers.com',
        'displayName': '   ',
      });
      expect(model.displayName, 'Tony Stark');
      expect(model.safeDisplayName, 'Tony Stark');
    });

    test(
      'replaces "Vowl Learner" case-insensitively with clean email derivation',
      () {
        final model = UserModel.fromMap({
          'id': 'u6',
          'email': 'ayesha.khan@gmail.com',
          'displayName': 'Vowl Learner',
        });
        expect(model.displayName, 'Ayesha Khan');
        expect(model.safeDisplayName, 'Ayesha Khan');
      },
    );

    test(
      'falls back gracefully when neither displayName nor email are valid',
      () {
        final model = UserModel.fromMap({
          'id': 'u5',
          'email': '',
          'displayName': 'Unknown User',
        });
        expect(model.displayName, isNull);
        expect(
          model.getSafeDisplayName(fallback: 'Anonymous Player'),
          'Anonymous Player',
        );
        expect(model.safeDisplayName, 'Vowl Learner');
      },
    );
  });

  group('UserModel Referral & PvP serialization', () {
    test('handles default referral and duel values correctly', () {
      final model = UserModel.fromMap({
        'id': 'u10',
        'email': 'player@vowl.app',
      });
      expect(model.hasClaimedReferral, false);
      expect(model.totalReferralsCount, 0);
      expect(model.monthlyReferralsCount, 0);
      expect(model.currentReferralMonthKey, isNull);
      expect(model.claimedAmbassadorRewardMonthKeys, isEmpty);
      expect(model.claimedWeeklyRewardWeekKeys, isEmpty);
      expect(model.dailyDuelsPlayedToday, 0);
      expect(model.duelWins, 0);
      expect(model.duelLosses, 0);
      expect(model.duelWinRate, 0.0);
    });

    test('serializes and deserializes referral and duel fields correctly', () {
      final now = DateTime.utc(2026, 11, 2, 10, 0);
      final model = UserModel(
        id: 'u11',
        email: 'ambassador@vowl.app',
        dailyXpHistory: const {},
        referralCode: 'VOWL-TEST',
        referredBy: 'VOWL-INVITER',
        hasClaimedReferral: true,
        totalReferralsCount: 15,
        monthlyReferralsCount: 5,
        currentReferralMonthKey: '2026-11',
        claimedAmbassadorRewardMonthKeys: const ['2026-10'],
        claimedWeeklyRewardWeekKeys: const ['2026-W43'],
        dailyDuelsPlayedToday: 3,
        lastDuelDate: now,
        duelWins: 8,
        duelLosses: 2,
      );

      expect(model.duelWinRate, 80.0);
      expect(model.activeMonthlyReferralsCount, 5);

      final map = model.toMap();
      final reconstructed = UserModel.fromMap(map);

      expect(reconstructed.referralCode, 'VOWL-TEST');
      expect(reconstructed.referredBy, 'VOWL-INVITER');
      expect(reconstructed.hasClaimedReferral, true);
      expect(reconstructed.totalReferralsCount, 15);
      expect(reconstructed.monthlyReferralsCount, 5);
      expect(reconstructed.currentReferralMonthKey, '2026-11');
      expect(reconstructed.claimedAmbassadorRewardMonthKeys, ['2026-10']);
      expect(reconstructed.claimedWeeklyRewardWeekKeys, ['2026-W43']);
      expect(reconstructed.dailyDuelsPlayedToday, 3);
      expect(reconstructed.duelWins, 8);
      expect(reconstructed.duelLosses, 2);
    });

    test(
      'serializes and deserializes weekly league previousRank and previousRankWeekKey correctly',
      () {
        final model = UserModel(
          id: 'u12',
          email: 'league.winner@vowl.app',
          dailyXpHistory: const {},
          previousRank: 1,
          previousRankWeekKey: '2026-W45',
          claimedWeeklyRewardWeekKeys: const ['2026-W44'],
        );

        final map = model.toMap();
        final reconstructed = UserModel.fromMap(map);

        expect(reconstructed.previousRank, 1);
        expect(reconstructed.previousRankWeekKey, '2026-W45');
        expect(reconstructed.claimedWeeklyRewardWeekKeys, ['2026-W44']);

        final copy = reconstructed.copyWith(
          previousRank: 2,
          previousRankWeekKey: '2026-W46',
        );
        expect(copy.previousRank, 2);
        expect(copy.previousRankWeekKey, '2026-W46');
      },
    );
  });
}
