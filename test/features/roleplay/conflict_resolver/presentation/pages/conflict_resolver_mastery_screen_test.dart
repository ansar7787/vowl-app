import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_mastery_screen.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_screen.dart';

void main() {
  test('ConflictResolverMasteryScreen is an alias of ConflictResolverScreen', () {
    const screen = ConflictResolverMasteryScreen(level: 1);
    expect(screen, isA<ConflictResolverScreen>());
  });
}
