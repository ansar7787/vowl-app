import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_learn_screen.dart';

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

  group('IdiomsLearnScreen', () {
    testWidgets(
        'renders idiom anatomy, emoji clues, origin story, and advances to next idiom',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const IdiomsLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(IdiomsLearnScreen), findsOneWidget);
      expect(find.text('FIGURATIVE MEANING'), findsOneWidget);
      expect(find.text('ORIGIN STORY'), findsOneWidget);
      expect(find.text('LITERAL VS FIGURATIVE'), findsOneWidget);
      expect(find.text('NATURAL CONVERSATION'), findsOneWidget);
      expect(find.textContaining('Next Idiom'), findsOneWidget);

      // Scroll and advance to next idiom
      final nextFinder = find.textContaining('Next Idiom');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('IDIOM 2 OF'), findsOneWidget);
    });
  });
}
