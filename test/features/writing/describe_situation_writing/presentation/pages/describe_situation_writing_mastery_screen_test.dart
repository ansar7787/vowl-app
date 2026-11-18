import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_mastery_screen.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_screen.dart';

void main() {
  group('DescribeSituationMasteryScreen', () {
    test('is a type alias of DescribeSituationScreen', () {
      const widget = DescribeSituationMasteryScreen(level: 1);
      expect(widget, isA<DescribeSituationScreen>());
      expect(widget.level, equals(1));
    });
  });
}
