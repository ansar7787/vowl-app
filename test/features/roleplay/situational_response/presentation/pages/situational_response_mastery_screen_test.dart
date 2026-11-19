import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/pages/situational_response_mastery_screen.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/pages/situational_response_screen.dart';

void main() {
  group('SituationalResponseMasteryScreen', () {
    test('is a type alias of SituationalResponseScreen', () {
      const widget = SituationalResponseMasteryScreen(level: 1);
      expect(widget, isA<SituationalResponseScreen>());
      expect(widget.level, equals(1));
    });
  });
}
