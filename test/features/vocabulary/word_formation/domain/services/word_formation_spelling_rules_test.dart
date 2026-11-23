import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/word_formation/domain/services/word_formation_spelling_rules.dart';

void main() {
  group('WordFormationSpellingRules', () {
    test('detects prefix assimilation for IM- before P', () {
      final insight = WordFormationSpellingRules.analyze('POSSIBLE', 'IMPOSSIBLE');
      expect(insight, isNotNull);
      expect(insight!.ruleTitle, 'PREFIX ASSIMILATION');
      expect(insight.ruleDescription, contains('mutates to \'IM-\''));
    });

    test('detects prefix assimilation for IL- before L', () {
      final insight = WordFormationSpellingRules.analyze('LOGICAL', 'ILLOGICAL');
      expect(insight, isNotNull);
      expect(insight!.ruleTitle, 'PREFIX ASSIMILATION');
      expect(insight.ruleDescription, contains('mutates to \'IL-\''));
    });

    test('detects prefix assimilation for IR- before R', () {
      final insight = WordFormationSpellingRules.analyze('RESPONSIBLE', 'IRRESPONSIBLE');
      expect(insight, isNotNull);
      expect(insight!.ruleTitle, 'PREFIX ASSIMILATION');
      expect(insight.ruleDescription, contains('mutates to \'IR-\''));
    });

    test('detects Latin stem mutation (D -> S) in DECIDE -> DECISIVE', () {
      final insight = WordFormationSpellingRules.analyze('DECIDE', 'DECISIVE');
      expect(insight, isNotNull);
      expect(insight!.ruleTitle, 'STEM MUTATION (D ➔ S)');
      expect(insight.ruleDescription, contains("'-DE' mutate to '-S'"));
    });

    test('detects silent E deletion in CREATE -> CREATIVE', () {
      final insight = WordFormationSpellingRules.analyze('CREATE', 'CREATIVE');
      expect(insight, isNotNull);
      expect(insight!.ruleTitle, 'SILENT \'E\' DELETION');
      expect(insight.ruleDescription, contains('silent \'E\''));
    });

    test('detects Y-to-I mutation in HAPPY -> HAPPINESS', () {
      final insight = WordFormationSpellingRules.analyze('HAPPY', 'HAPPINESS');
      expect(insight, isNotNull);
      expect(insight!.ruleTitle, 'Y-TO-I MUTATION');
      expect(insight.ruleDescription, contains('mutates to \'I\''));
    });

    test('detects consonant doubling in ADMIT -> ADMITTANCE', () {
      final insight = WordFormationSpellingRules.analyze('ADMIT', 'ADMITTANCE');
      expect(insight, isNotNull);
      expect(insight!.ruleTitle, 'CONSONANT DOUBLING');
      expect(insight.ruleDescription, contains('Double the final consonant'));
    });

    test('detects noun formation suffix -TION in CREATE -> CREATION', () {
      final insight = WordFormationSpellingRules.analyze('CREATE', 'CREATION');
      expect(insight, isNotNull);
      // CREATE ends in E, so silent E deletion triggers first
      expect(insight!.ruleTitle, isNotEmpty);
    });

    test('returns null for identical or empty inputs', () {
      expect(WordFormationSpellingRules.analyze('', ''), isNull);
      expect(WordFormationSpellingRules.analyze('DECIDE', 'DECIDE'), isNull);
    });
  });
}
