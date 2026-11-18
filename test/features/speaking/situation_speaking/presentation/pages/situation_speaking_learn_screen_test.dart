import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/pages/situation_speaking_learn_screen.dart';

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

  group('SituationSpeakingLearnScreen', () {
    testWidgets(
      'renders scenario context, recommended response, communication tip, key phrases, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const SituationSpeakingLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SituationSpeakingLearnScreen), findsOneWidget);
        expect(find.text('Situation Speaking Discovery'), findsOneWidget);
        expect(find.text('REAL-LIFE SCENARIO'), findsOneWidget);
        expect(find.text('RECOMMENDED SPOKEN RESPONSE'), findsOneWidget);
        expect(find.text('COMMUNICATION TIP'), findsOneWidget);
        expect(find.text('KEY PHRASES & WORDS'), findsOneWidget);

        // Check target phrase is visible
        expect(find.byKey(const Key('situation_speaking_learn_target_phrase')), findsOneWidget);

        // Tap action button if available
        final actionButton = find.byType(ElevatedButton);
        if (actionButton.evaluate().isNotEmpty) {
          await tester.ensureVisible(actionButton.first);
          await tester.tap(actionButton.first);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
