import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/pages/short_answer_writing_learn_screen.dart';

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

  group('ShortAnswerWritingLearnScreen', () {
    testWidgets(
      'renders conversation situation, mandatory keywords, model concise response, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ShortAnswerWritingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ShortAnswerWritingLearnScreen), findsOneWidget);
        expect(find.text('CONVERSATION SITUATION'), findsOneWidget);
        expect(find.text('MANDATORY KEYWORD TOKENS'), findsOneWidget);
        expect(find.text('MODEL CONCISE RESPONSE'), findsOneWidget);

        // Tap Next Situation Card
        final nextFinder = find.text('Next Situation Card');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextFinder);
          await tester.tap(nextFinder);
          await tester.pumpAndSettle();
          expect(find.textContaining('SITUATION 2 OF'), findsOneWidget);
        }
      },
    );
  });
}
