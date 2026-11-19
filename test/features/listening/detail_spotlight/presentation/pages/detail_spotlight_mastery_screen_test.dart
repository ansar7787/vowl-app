import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_mastery_screen.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_screen.dart';

void main() {
  group('DetailSpotlightMasteryScreen', () {
    test('is a type alias of DetailSpotlightScreen', () {
      const widget = DetailSpotlightMasteryScreen(level: 1);
      expect(widget, isA<DetailSpotlightScreen>());
      expect(widget.level, equals(1));
    });
  });
}
