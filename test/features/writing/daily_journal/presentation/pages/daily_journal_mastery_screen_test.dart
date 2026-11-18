import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/daily_journal/presentation/pages/daily_journal_mastery_screen.dart';
import 'package:vowl/features/writing/daily_journal/presentation/pages/daily_journal_screen.dart';

void main() {
  group('DailyJournalMasteryScreen', () {
    test('is a type alias of DailyJournalScreen', () {
      const widget = DailyJournalMasteryScreen(level: 1);
      expect(widget, isA<DailyJournalScreen>());
      expect(widget.level, equals(1));
    });
  });
}
