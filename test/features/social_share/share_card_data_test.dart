import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';

void main() {
  group('ShareCardData', () {
    test('creates rank share card correctly', () {
      final card = ShareCardData.fromRank(
        userName: 'Alex Johnson',
        userPhotoUrl: 'https://example.com/avatar.jpg',
        rank: 3,
        totalXp: 1540,
        streak: 12,
        referralCode: 'VOWL-ALEX892',
      );

      expect(card.userName, 'Alex Johnson');
      expect(card.rank, 3);
      expect(card.totalXp, 1540);
      expect(card.streak, 12);
      expect(card.title, 'Rank #3 Global Standing');
      expect(card.subtitle, '1540 Total XP · 12-Day Streak');
      expect(card.referralCode, 'VOWL-ALEX892');
    });

    test('creates streak share card correctly', () {
      final card = ShareCardData.fromStreak(
        userName: 'Sarah',
        streak: 30,
        totalXp: 4500,
        referralCode: 'VOWL-SARAH123',
      );

      expect(card.userName, 'Sarah');
      expect(card.streak, 30);
      expect(card.title, '30-Day Learning Streak');
      expect(card.subtitle, 'Committed to English mastery on Vowl');
      expect(card.referralCode, 'VOWL-SARAH123');
    });
  });
}

