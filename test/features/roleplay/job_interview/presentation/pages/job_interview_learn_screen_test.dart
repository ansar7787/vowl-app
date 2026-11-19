import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/pages/job_interview_learn_screen.dart';

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

  group('JobInterviewLearnScreen', () {
    testWidgets(
      'renders question card, STAR pillars, optimal response, strategy card and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const JobInterviewLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(JobInterviewLearnScreen), findsOneWidget);
        expect(find.text('Job Interview'), findsOneWidget);
        expect(find.text('INTERVIEWER QUESTION'), findsOneWidget);
        expect(find.text('STAR STRUCTURE BREAKDOWN'), findsOneWidget);

        // Verify STAR pillar letters exist
        expect(find.text('S'), findsOneWidget);
        expect(find.text('T'), findsOneWidget);
        expect(find.text('A'), findsOneWidget);
        expect(find.text('R'), findsOneWidget);

        // Verify Model Response Card
        expect(find.byKey(const Key('interview_learn_optimal_card')), findsOneWidget);

        // Verify Audio button
        final audioBtn = find.byKey(const Key('interview_learn_audio_btn'));
        expect(audioBtn, findsOneWidget);
        await tester.ensureVisible(audioBtn);
        await tester.tap(audioBtn);
        await tester.pump();

        // Verify Strategy card
        expect(find.byKey(const Key('interview_learn_strategy_card')), findsOneWidget);

        // Tap Next
        final nextBtn = find.text('NEXT QUESTION');
        if (nextBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextBtn);
          await tester.tap(nextBtn);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
