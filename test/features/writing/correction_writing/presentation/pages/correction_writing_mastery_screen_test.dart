import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/correction_writing/presentation/pages/correction_writing_mastery_screen.dart';
import 'package:vowl/features/writing/correction_writing/presentation/pages/correction_writing_screen.dart';

void main() {
  group('CorrectionWritingMasteryScreen', () {
    test('is a type alias of CorrectionWritingScreen', () {
      const widget = CorrectionWritingMasteryScreen(level: 1);
      expect(widget, isA<CorrectionWritingScreen>());
      expect(widget.level, equals(1));
    });
  });
}
