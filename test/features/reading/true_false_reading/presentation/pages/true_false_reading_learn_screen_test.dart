import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/pages/true_false_reading_learn_screen.dart';

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

  group('TrueFalseReadingLearnScreen', () {
    testWidgets(
      'renders Fact vs Inference Guide, statement, evidence line, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const TrueFalseReadingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TrueFalseReadingLearnScreen), findsOneWidget);
        expect(find.text('Fact vs Inference Guide'), findsOneWidget);
        expect(find.text('STATEMENT TO EVALUATE'), findsOneWidget);
        expect(find.textContaining('Mia grows beans'), findsWidgets);
        expect(find.text('READING COMPREHENSION RULE'), findsOneWidget);
        expect(find.textContaining('NEXT GUIDE CARD'), findsOneWidget);

        // Tap NEXT GUIDE CARD
        final nextFinder = find.textContaining('NEXT GUIDE CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Card 2 of'), findsOneWidget);
        expect(find.textContaining('helmet'), findsWidgets);
      },
    );
  });
}
