import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/domain/entities/game_phase.dart';

void main() {
  group('GamePhase Enum', () {
    test('provides correct display names and emojis', () {
      expect(GamePhase.learn.displayName, equals('LEARN'));
      expect(GamePhase.practice.displayName, equals('PRACTICE'));
      expect(GamePhase.mastery.displayName, equals('MASTERY'));
      expect(GamePhase.test.displayName, equals('MASTERY'));

      expect(GamePhase.learn.emoji, equals('🧠'));
      expect(GamePhase.practice.emoji, equals('✋'));
      expect(GamePhase.mastery.emoji, equals('🏆'));
      expect(GamePhase.test.emoji, equals('🏆'));
    });

    test('fromString parses strings correctly with graceful fallbacks', () {
      expect(GamePhase.fromString('learn'), equals(GamePhase.learn));
      expect(GamePhase.fromString('PRACTICE'), equals(GamePhase.practice));
      expect(GamePhase.fromString('mastery'), equals(GamePhase.mastery));
      expect(GamePhase.fromString(' Test '), equals(GamePhase.mastery));
      expect(GamePhase.fromString('unknown'), equals(GamePhase.learn));
      expect(GamePhase.fromString(null), equals(GamePhase.learn));
    });
  });
}
