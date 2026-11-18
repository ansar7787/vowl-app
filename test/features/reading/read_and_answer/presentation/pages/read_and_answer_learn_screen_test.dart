import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/pages/read_and_answer_learn_screen.dart';

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

  group('ReadAndAnswerLearnScreen', () {
    testWidgets(
      'renders Pre-Reading Schema Activation, passage, strategy, evidence spotlight, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ReadAndAnswerLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ReadAndAnswerLearnScreen), findsOneWidget);
        expect(find.text('Pre-Reading Schema Activation'), findsOneWidget);
        expect(find.text('READING STRATEGY'), findsOneWidget);
        expect(find.text('EVIDENCE SPOTLIGHT'), findsOneWidget);
        expect(find.textContaining('NEXT SCHEMA CARD'), findsOneWidget);

        // Tap NEXT SCHEMA CARD
        final nextFinder = find.textContaining('NEXT SCHEMA CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Passage 2 of'), findsOneWidget);
      },
    );
  });
}
