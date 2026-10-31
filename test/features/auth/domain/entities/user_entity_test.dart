import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    const tUser = UserEntity(
      id: '1',
      email: 'test@vowl.com',
      totalExp: 250, // Should be Level 3 ((250/100).floor() + 1 = 2+1 = 3)
      categoryStats: {'sentenceCorrection': 50, 'wordReorder': 30},
    );

    test('should calculate level correctly from totalExp', () {
      expect(tUser.level, 3);

      final level10User = tUser.copyWith(totalExp: 950);
      expect(level10User.level, 10);
    });

    test('should calculate category progress as the max of its subtypes', () {
      // sentenceCorrection and wordReorder are subtypes of Grammar
      expect(tUser.grammarMastery, 50);

      final updatedUser = tUser.copyWith(
        categoryStats: {'sentenceCorrection': 50, 'wordReorder': 80},
      );
      expect(updatedUser.grammarMastery, 80);
    });

    test('should identify if double XP is active', () {
      final inactiveUser = tUser.copyWith(doubleXPExpiry: null);
      expect(inactiveUser.isDoubleXPActive, false);

      final activeUser = tUser.copyWith(
        doubleXPExpiry: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(activeUser.isDoubleXPActive, true);

      final expiredUser = tUser.copyWith(
        doubleXPExpiry: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(expiredUser.isDoubleXPActive, false);
    });

    test('should identify if VIP gift is available', () {
      final nonPremiumUser = tUser.copyWith(isPremium: false);
      expect(nonPremiumUser.isVipGiftAvailable, false);

      final premiumUser = tUser.copyWith(
        isPremium: true,
        lastVipGiftDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(premiumUser.isVipGiftAvailable, true);

      final premiumUserAlreadyClaimed = tUser.copyWith(
        isPremium: true,
        lastVipGiftDate: DateTime.now(),
      );
      expect(premiumUserAlreadyClaimed.isVipGiftAvailable, false);
    });

    test('getSafeDisplayName returns valid displayName when present', () {
      final user = tUser.copyWith(displayName: 'Alice Johnson');
      expect(user.getSafeDisplayName(), 'Alice Johnson');
      expect(user.safeDisplayName, 'Alice Johnson');
    });

    test('getSafeDisplayName sanitizes "Unknown User" and formats from email', () {
      const user = UserEntity(
        id: '2',
        email: 'alex.smith@example.com',
        displayName: 'Unknown User',
        dailyXpHistory: {},
      );
      expect(user.getSafeDisplayName(), 'Alex Smith');
      expect(user.safeDisplayName, 'Alex Smith');
    });

    test('getSafeDisplayName sanitizes "unknown" and formats dotted/dashed email prefix', () {
      const user = UserEntity(
        id: '3',
        email: 'john_doe-42@example.com',
        displayName: 'Unknown',
        dailyXpHistory: {},
      );
      expect(user.getSafeDisplayName(), 'John Doe');
    });

    test('getSafeDisplayName uses custom fallback when name is invalid and email is empty', () {
      const user = UserEntity(
        id: '99',
        email: '',
        displayName: 'Unknown User',
        dailyXpHistory: {},
      );
      expect(user.getSafeDisplayName(fallback: 'Champion'), 'Champion');
      expect(user.safeDisplayName, 'Vowl Learner');
    });
  });
}
