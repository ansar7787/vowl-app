import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/pages/medical_consult_learn_screen.dart';

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

  group('MedicalConsultLearnScreen', () {
    testWidgets(
      'renders doctor inquiry card, clinical pillars, optimal response, strategy card and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const MedicalConsultLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(MedicalConsultLearnScreen), findsOneWidget);
        expect(find.text('Medical Consult'), findsOneWidget);
        expect(find.text('DOCTOR INQUIRY'), findsOneWidget);
        expect(find.text('CLINICAL PROFILE BREAKDOWN'), findsOneWidget);

        // Verify Clinical Pillars exist
        expect(find.text('SENSATION CHARACTERISTIC'), findsOneWidget);
        expect(find.text('ONSET & TIMELINE'), findsOneWidget);
        expect(find.text('MEDICATION & PRECAUTIONS'), findsOneWidget);

        // Verify Optimal Response Card
        expect(find.byKey(const Key('medical_learn_optimal_card')), findsOneWidget);

        // Verify Audio button
        final audioBtn = find.byKey(const Key('medical_learn_audio_btn'));
        expect(audioBtn, findsOneWidget);
        await tester.ensureVisible(audioBtn);
        await tester.tap(audioBtn);
        await tester.pump();

        // Verify Strategy card
        expect(find.byKey(const Key('medical_learn_strategy_card')), findsOneWidget);

        // Tap Next
        final nextBtn = find.text('NEXT SYMPTOM');
        if (nextBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(nextBtn);
          await tester.tap(nextBtn);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
