import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_practice_screen.dart';

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

  group('VowelDistinctionPracticeScreen', () {
    testWidgets(
      'renders target word, selects vowel option, checks answer and displays explanation',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const VowelDistinctionPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(VowelDistinctionPracticeScreen), findsOneWidget);
        expect(find.text('Vowel Target Practice Gym'), findsOneWidget);
        expect(find.text('TARGET WORD'), findsOneWidget);

        // Check listen button
        expect(
          find.byKey(const Key('practice_listen_button')),
          findsOneWidget,
        );

        // Tap listen button
        await tester.tap(find.byKey(const Key('practice_listen_button')));
        await tester.pumpAndSettle();

        // Select first option
        final firstOptionFinder = find.byKey(const Key('practice_option_0'));
        expect(firstOptionFinder, findsOneWidget);
        await tester.ensureVisible(firstOptionFinder);
        await tester.tap(firstOptionFinder);
        await tester.pumpAndSettle();

        // Tap Check Answer button
        final checkFinder = find.byKey(const Key('practice_check_button'));
        expect(checkFinder, findsOneWidget);
        await tester.ensureVisible(checkFinder);
        await tester.tap(checkFinder);
        await tester.pumpAndSettle();

        // Verify explanation card appears
        expect(
          find.byKey(const Key('practice_explanation_card')),
          findsOneWidget,
        );

        // Tap Continue / Next button
        final continueFinder =
            find.byKey(const Key('practice_continue_button'));
        expect(continueFinder, findsOneWidget);
        await tester.ensureVisible(continueFinder);
        await tester.tap(continueFinder);
        await tester.pumpAndSettle();
      },
    );
  });
}
