import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_mastery_screen.dart';
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_screen.dart';

void main() {
  test('SpeedSpellingMasteryScreen is an alias of SpeedSpellingScreen', () {
    const screen = SpeedSpellingMasteryScreen(level: 1);
    expect(screen, isA<SpeedSpellingScreen>());
  });
}
