import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_mastery_screen.dart';

void main() {
  group('SubjectVerbAgreementMasteryScreen Type Alias', () {
    test('SubjectVerbAgreementMasteryScreen resolves identically to SubjectVerbAgreementScreen', () {
      expect(SubjectVerbAgreementMasteryScreen, equals(SubjectVerbAgreementScreen));
    });

    test('can instantiate SubjectVerbAgreementMasteryScreen with level and gameType', () {
      const screen = SubjectVerbAgreementMasteryScreen(level: 2);
      expect(screen.level, equals(2));
      expect(screen, isA<SubjectVerbAgreementScreen>());
    });
  });
}
