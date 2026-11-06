import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/arena/data/utils/arena_ai_difficulty_engine.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

void main() {
  group('3-Pillar Skill-Based Matchmaking (SBMM) ArenaAiOpponent Tests', () {
    test('Novice player (Level 2, 0 duels) produces authentic Computer with tier', () {
      final opponent = ArenaAiOpponent.calculateSkillMatchedOpponent(
        playerLevel: 2,
        totalDuels: 0,
        consecutiveWins: 0,
      );

      expect(opponent.displayName, 'Computer');
      expect(['EASY', 'MEDIUM', 'HARD'], contains(opponent.tierLabel));
      expect(opponent.accuracy, inInclusiveRange(0.60, 0.94));
    });

    test('Master/Pro player (Level 35, 85% Win Rate) is NEVER matched with Easy bot (Anti-Farm Guarantee)', () {
      // Test across 100 deterministic rolls to prove 0% Easy probability
      for (int i = 0; i < 100; i++) {
        final opponent = ArenaAiOpponent.calculateSkillMatchedOpponent(
          playerLevel: 35,
          winRate: 85.0,
          totalDuels: 20,
          consecutiveWins: 0,
          random: Random(i),
        );

        expect(
          opponent.tier,
          isNot(equals(ArenaAiDifficultyTier.easy)),
          reason: 'Roll $i for master player should never result in Easy tier',
        );
        expect(['MEDIUM', 'HARD'], contains(opponent.tierLabel));
        expect(opponent.accuracy, inInclusiveRange(0.75, 0.94));
      }
    });

    test('Consecutive win streak of 3+ escalates any player to eliminate Easy bot farming', () {
      // Even a Level 1 player on a 3-match win streak must face Medium/Hard bots
      for (int i = 0; i < 50; i++) {
        final opponent = ArenaAiOpponent.calculateSkillMatchedOpponent(
          playerLevel: 1,
          winRate: 100.0,
          totalDuels: 3,
          consecutiveWins: 3,
          random: Random(i),
        );

        expect(
          opponent.tier,
          isNot(equals(ArenaAiDifficultyTier.easy)),
          reason: 'Win-streak momentum must eliminate Easy bot farming',
        );
      }
    });

    test('Organic accuracy micro-variance produces varied, human-like bot stats', () {
      final opponent1 = ArenaAiOpponent.calculateSkillMatchedOpponent(
        playerLevel: 10,
        random: Random(42),
      );
      final opponent2 = ArenaAiOpponent.calculateSkillMatchedOpponent(
        playerLevel: 10,
        random: Random(99),
      );

      expect(opponent1.displayName, 'Computer');
      expect(opponent2.displayName, 'Computer');
      expect(opponent1.accuracy, isPositive);
      expect(opponent2.accuracy, isPositive);
    });

    test('forPlayer factory correctly extracts stats from UserEntity', () {
      const user = UserEntity(
        id: 'u123',
        email: 'test@vowl.app',
        displayName: 'Champion',
        coins: 100,
        totalExp: 2500, // Level 26
        duelWins: 15,
        duelLosses: 5, // 75% Win Rate, 20 Total Duels
      );

      final opponent = ArenaAiOpponent.forPlayer(
        user,
        consecutiveWins: 2,
        random: Random(123),
      );

      expect(opponent.displayName, 'Computer');
      expect(opponent.tier, isNot(equals(ArenaAiDifficultyTier.easy)));
    });

    test('Backwards-compatible forPlayerLevel functions reliably', () {
      final easyOpponent = ArenaAiOpponent.forPlayerLevel(3, random: Random(1));
      expect(easyOpponent.displayName, 'Computer');
      expect(easyOpponent.minResponseSeconds, inInclusiveRange(2, 3));
      expect(easyOpponent.maxResponseSeconds, inInclusiveRange(3, 5));
    });
  });
}

