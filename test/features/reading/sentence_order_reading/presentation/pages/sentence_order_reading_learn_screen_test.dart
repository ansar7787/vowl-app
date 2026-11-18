import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_learn_screen.dart';

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

  group('SentenceOrderReadingLearnScreen', () {
    testWidgets(
      'renders Cohesion & Transition Markers, sequence flow, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SentenceOrderReadingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SentenceOrderReadingLearnScreen), findsOneWidget);
        expect(find.text('Cohesion & Transition Markers'), findsOneWidget);
        expect(find.text('LOGICAL SEQUENCE FLOW'), findsOneWidget);
        expect(find.text('COHESION BREAKDOWN'), findsOneWidget);
        expect(find.textContaining('Next Cohesion Strategy'), findsOneWidget);

        // Tap Next Cohesion Strategy to advance to Card 2
        final nextFinder = find.textContaining('Next Cohesion Strategy');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Card 2 of'), findsOneWidget);
      },
    );
  });
}
