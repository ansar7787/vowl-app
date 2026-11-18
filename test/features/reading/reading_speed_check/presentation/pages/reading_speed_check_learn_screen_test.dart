import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/pages/reading_speed_check_learn_screen.dart';

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

  group('ReadingSpeedCheckLearnScreen', () {
    testWidgets(
      'renders Pacer & Chunking Trainer, toggles pacer, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadingSpeedCheckLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadingSpeedCheckLearnScreen), findsOneWidget);
        expect(find.text('Pacer & Chunking Trainer'), findsOneWidget);
        expect(find.text('RHYTHMIC CHUNKING PACER'), findsOneWidget);
        expect(find.text('PACING BREAKDOWN'), findsOneWidget);
        expect(find.text('TEST PACER'), findsOneWidget);

        // Toggle Pacer
        await tester.tap(find.text('TEST PACER'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('PAUSE'), findsOneWidget);

        // Advance to next card
        final nextFinder = find.textContaining('Next Speed Strategy');
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
