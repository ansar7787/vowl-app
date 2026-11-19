import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/elite_mastery/idiom_match/presentation/pages/idiom_match_mastery_screen.dart';
import 'package:vowl/features/elite_mastery/idiom_match/presentation/pages/idiom_match_screen.dart';

void main() {
  test('IdiomMatchMasteryScreen is an alias of IdiomMatchScreen', () {
    const screen = IdiomMatchMasteryScreen(level: 1);
    expect(screen, isA<IdiomMatchScreen>());
  });
}
