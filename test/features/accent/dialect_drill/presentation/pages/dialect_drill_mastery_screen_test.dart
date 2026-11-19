import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/pages/dialect_drill_mastery_screen.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/pages/dialect_drill_screen.dart';

void main() {
  group('DialectDrillMasteryScreen', () {
    test('is a type alias of DialectDrillScreen', () {
      const widget = DialectDrillMasteryScreen(level: 1);
      expect(widget, isA<DialectDrillScreen>());
      expect(widget.level, equals(1));
    });
  });
}
