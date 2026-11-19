import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/speed_variance/presentation/pages/speed_variance_mastery_screen.dart';
import 'package:vowl/features/accent/speed_variance/presentation/pages/speed_variance_screen.dart';

void main() {
  group('SpeedVarianceMasteryScreen', () {
    test('is a type alias of SpeedVarianceScreen', () {
      const widget = SpeedVarianceMasteryScreen(level: 1);
      expect(widget, isA<SpeedVarianceScreen>());
      expect(widget.level, equals(1));
    });
  });
}
