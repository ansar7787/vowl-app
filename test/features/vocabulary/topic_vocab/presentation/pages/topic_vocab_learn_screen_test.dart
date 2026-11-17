import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_learn_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    );
  }

  group('TopicVocabLearnScreen', () {
    testWidgets(
        'renders category buckets, overview, word definitions, sorting strategy, and advances',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TopicVocabLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TopicVocabLearnScreen), findsOneWidget);
      expect(find.text('CATEGORY OVERVIEW'), findsOneWidget);
      expect(find.text('WORD DEFINITIONS & LINKAGES'), findsOneWidget);
      expect(find.text('SORTING STRATEGY'), findsOneWidget);
      expect(find.textContaining('Next Topic'), findsOneWidget);

      // Scroll and advance to next topic
      final nextFinder = find.textContaining('Next Topic');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('THEME 2 OF'), findsOneWidget);
    });
  });
}
