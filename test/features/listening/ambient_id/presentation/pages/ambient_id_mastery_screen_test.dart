import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/ambient_id/presentation/pages/ambient_id_mastery_screen.dart';
import 'package:vowl/features/listening/ambient_id/presentation/pages/ambient_id_screen.dart';

void main() {
  group('AmbientIdMasteryScreen', () {
    test('is a type alias of AmbientIdScreen', () {
      const widget = AmbientIdMasteryScreen(level: 1);
      expect(widget, isA<AmbientIdScreen>());
      expect(widget.level, equals(1));
    });
  });
}
