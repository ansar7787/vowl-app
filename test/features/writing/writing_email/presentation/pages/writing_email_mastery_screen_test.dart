import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/writing_email/presentation/pages/writing_email_mastery_screen.dart';
import 'package:vowl/features/writing/writing_email/presentation/pages/writing_email_screen.dart';

void main() {
  group('WritingEmailMasteryScreen', () {
    test('is a type alias of WritingEmailScreen', () {
      const widget = WritingEmailMasteryScreen(level: 1);
      expect(widget, isA<WritingEmailScreen>());
      expect(widget.level, equals(1));
    });
  });
}
