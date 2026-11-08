import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity - hasActivePremium & pendingReferralCode', () {
    test('returns false when isPremium is false even if date is future', () {
      final user = UserEntity(
        id: 'u1',
        email: 'test@vowl.com',
        isPremium: false,
        premiumExpiryDate: DateTime.now().add(const Duration(days: 7)),
      );
      expect(user.hasActivePremium, false);
    });

    test('returns true when isPremium is true and expiry is null', () {
      final user = const UserEntity(
        id: 'u1',
        email: 'test@vowl.com',
        isPremium: true,
        premiumExpiryDate: null,
      );
      expect(user.hasActivePremium, true);
    });

    test('returns true when isPremium is true and expiry is in the future', () {
      final user = UserEntity(
        id: 'u1',
        email: 'test@vowl.com',
        isPremium: true,
        premiumExpiryDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(user.hasActivePremium, true);
    });

    test(
      'returns false when isPremium is true but expiry date is in the past (Critical Fix)',
      () {
        final user = UserEntity(
          id: 'u1',
          email: 'test@vowl.com',
          isPremium: true,
          // Expired in Oct 2026
          premiumExpiryDate: DateTime.now().subtract(const Duration(days: 10)),
        );
        expect(user.hasActivePremium, false);
      },
    );

    test('correctly retains pendingReferralCode through copyWith', () {
      const user = UserEntity(
        id: 'u1',
        email: 'test@vowl.com',
        pendingReferralCode: 'VOWL-ALICE123',
      );
      expect(user.pendingReferralCode, 'VOWL-ALICE123');

      final updated = user.copyWith(pendingReferralCode: 'VOWL-BOB456');
      expect(updated.pendingReferralCode, 'VOWL-BOB456');

      final cleared = updated.copyWith(pendingReferralCode: null);
      // copyWith nullable handling
      expect(cleared.id, 'u1');
    });
  });
}
