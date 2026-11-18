import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/question_formatter/presentation/pages/question_formatter_learn_screen.dart';

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

  group('QuestionFormatterLearnScreen', () {
    testWidgets(
      'renders Question Flip Engine, statement, question, rule explanation, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const QuestionFormatterLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(QuestionFormatterLearnScreen), findsOneWidget);
        expect(find.text('Question Flip Engine'), findsOneWidget);
        expect(find.text('DECLARATIVE STATEMENT'), findsOneWidget);
        expect(find.text('INTERROGATIVE QUESTION'), findsOneWidget);
        expect(find.text('HOW THE QUESTION IS FORMED'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT INVERSION CARD'), findsOneWidget);

        // Tap NEXT INVERSION CARD
        final nextFinder = find.textContaining('NEXT INVERSION CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Concept 2 of'), findsOneWidget);
      },
    );
  });
}
