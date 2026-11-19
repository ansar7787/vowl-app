import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_mastery_screen.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_screen.dart';

void main() {
  group('MinimalPairsMasteryScreen', () {
    test('is a type alias of MinimalPairsScreen', () {
      const widget = MinimalPairsMasteryScreen(level: 1);
      expect(widget, isA<MinimalPairsScreen>());
      expect(widget.level, equals(1));
    });
  });
}
