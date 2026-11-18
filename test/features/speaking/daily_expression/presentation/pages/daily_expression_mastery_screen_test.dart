import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/pages/daily_expression_mastery_screen.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/pages/daily_expression_screen.dart';

void main() {
  group('DailyExpressionMasteryScreen', () {
    test('is a type alias of DailyExpressionScreen', () {
      const widget = DailyExpressionMasteryScreen(level: 1);
      expect(widget, isA<DailyExpressionScreen>());
      expect(widget.level, equals(1));
    });
  });
}
