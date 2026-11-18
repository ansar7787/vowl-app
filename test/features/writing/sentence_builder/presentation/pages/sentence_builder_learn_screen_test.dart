import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_learn_screen.dart';

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

  group('SentenceBuilderLearnScreen', () {
    testWidgets(
      'renders Syntactic Block Architecture, cadence pattern, semantic building blocks, and advances card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SentenceBuilderLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SentenceBuilderLearnScreen), findsOneWidget);
        expect(find.text('SYNTAX ARCHITECTURE'), findsOneWidget);
        expect(find.text('COMPLETE NATURAL CADENCE'), findsOneWidget);
        expect(find.text('SYNTACTIC BUILDING BLOCKS'), findsOneWidget);
        expect(find.text('SYNTACTIC PRINCIPLE'), findsOneWidget);
        expect(find.text('AVOID UNNATURAL WORD ORDER'), findsOneWidget);

        // Advance to next pattern
        final nextFinder = find.text('Next Pattern');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('PATTERN 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
