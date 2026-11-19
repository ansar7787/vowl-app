import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/pages/accent_shadowing_mastery_screen.dart';
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/pages/accent_shadowing_screen.dart';

void main() {
  test('AccentShadowingMasteryScreen is an alias of AccentShadowingScreen', () {
    const screen = AccentShadowingMasteryScreen(level: 1);
    expect(screen, isA<AccentShadowingScreen>());
  });
}
