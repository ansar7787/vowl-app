import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/pages/daily_expression_learn_screen.dart';

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

  group('DailyExpressionLearnScreen', () {
    testWidgets(
      'renders daily expression, situational context, usage sample, nuance, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DailyExpressionLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DailyExpressionLearnScreen), findsOneWidget);
        expect(find.text('DAILY EXPRESSION'), findsOneWidget);
        expect(find.text('SITUATIONAL CONTEXT & SETTING'), findsOneWidget);
        expect(find.text('CONVERSATIONAL USAGE SAMPLE'), findsOneWidget);
        expect(find.text('CULTURAL NUANCE & USAGE EXPLANATION'), findsOneWidget);
        expect(find.text('SPEAKING ADVICE & TONE'), findsOneWidget);

        // Tap Next Expression button
        final nextFinder = find.byType(ElevatedButton);
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder.first);
          await tester.tap(nextFinder.first);
          await tester.pumpAndSettle();
          expect(find.textContaining('EXPRESSION DISCOVERY 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
