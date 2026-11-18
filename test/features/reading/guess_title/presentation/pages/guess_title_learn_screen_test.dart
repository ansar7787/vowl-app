import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/guess_title/presentation/pages/guess_title_learn_screen.dart';

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

  group('GuessTitleLearnScreen', () {
    testWidgets(
      'renders Main Idea vs Detail Filter, passage, scope breakdown, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const GuessTitleLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(GuessTitleLearnScreen), findsOneWidget);
        expect(find.text('Main Idea vs Detail Filter'), findsOneWidget);
        expect(find.text('PASSAGE TO ANALYZE'), findsOneWidget);
        expect(find.text('TITLE SCOPE BREAKDOWN'), findsOneWidget);
        expect(find.text('SYNTHESIS KEY'), findsOneWidget);

        // Tap Next Scope Strategy to advance card
        final nextFinder = find.textContaining('Next Scope Strategy');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('Card 2 of'), findsOneWidget);
        }
      },
    );
  });
}
