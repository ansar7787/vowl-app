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
      expect(card.title, 'Rank #3 on Vowl');
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
      expect(card.subtitle, '30 days of learning English on Vowl');
      expect(card.referralCode, 'VOWL-SARAH123');
    });

    test('creates arena victory share card correctly with real rival name', () {
      final card = ShareCardData.fromArenaVictory(
        userName: 'Ansar',
        myScore: 450,
        rivalScore: 320,
        rivalName: 'John',
        roomCode: 'VOWL99',
        payoutCoins: 50,
      );

      expect(card.userName, 'Ansar');
      expect(card.myScore, 450);
      expect(card.rivalScore, 320);
      expect(card.rivalName, 'John');
      expect(card.title, '1v1 DUEL WINNER');
      expect(card.subtitle, 'Beat John in a 1v1 English Duel');
      expect(card.roomCode, 'VOWL99');
      expect(card.payoutCoins, 50);
    });

    test('creates arena defeat share card with arenaDefeat type and contender copy', () {
      final card = ShareCardData.fromArenaDefeat(
        userName: 'Ansar',
        myScore: 280,
        rivalScore: 410,
        rivalName: 'John',
        roomCode: 'VOWL-DUEL-482913',
        payoutCoins: 10,
      );

      expect(card.type, ShareCardType.arenaDefeat);
      expect(card.title, '1v1 DUEL CONTENDER');
      expect(card.subtitle, 'Battled John in a 1v1 English Duel — rematch incoming!');
      expect(card.payoutCoins, 10);
    });

    test('creates arena draw share card with arenaDraw type', () {
      final card = ShareCardData.fromArenaDraw(
        userName: 'Ansar',
        myScore: 350,
        rivalScore: 350,
        rivalName: 'John',
        roomCode: 'VOWL-DUEL-482913',
        payoutCoins: 30,
      );

      expect(card.type, ShareCardType.arenaDraw);
      expect(card.title, '1v1 DUEL DRAW');
      expect(card.payoutCoins, 30);
    });

    test('creates weekly rank share card with Weekly XP label', () {
      final card = ShareCardData.fromRank(
        userName: 'Alex',
        rank: 2,
        totalXp: 450,
        streak: 5,
        isWeekly: true,
      );

      expect(card.isWeeklyRank, isTrue);
      expect(card.subtitle, '450 Weekly XP · 5-Day Streak');
    });
  });
}
