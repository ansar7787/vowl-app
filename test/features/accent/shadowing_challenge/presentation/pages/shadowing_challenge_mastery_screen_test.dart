import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_mastery_screen.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_screen.dart';

void main() {
  group('ShadowingChallengeMasteryScreen', () {
    test('is a type alias of ShadowingChallengeScreen', () {
      const widget = ShadowingChallengeMasteryScreen(level: 1);
      expect(widget, isA<ShadowingChallengeScreen>());
      expect(widget.level, equals(1));
    });
  });
}
