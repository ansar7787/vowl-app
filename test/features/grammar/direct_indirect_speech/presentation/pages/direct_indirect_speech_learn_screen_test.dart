import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/pages/direct_indirect_speech_learn_screen.dart';

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

  group('DirectIndirectSpeechLearnScreen', () {
    testWidgets(
      'renders Speech Bubble to Report Converter, quote, reported speech, principles, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const DirectIndirectSpeechLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DirectIndirectSpeechLearnScreen), findsOneWidget);
        expect(find.text('Speech Bubble to Report Converter'), findsOneWidget);
        expect(find.text('DIRECT SPEECH (QUOTED)'), findsOneWidget);
        expect(find.text('REPORTED SPEECH (INDIRECT)'), findsOneWidget);
        expect(find.text('GRAMMAR PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER CADENCE TIP'), findsOneWidget);
        expect(find.textContaining('NEXT CONVERSION CARD'), findsOneWidget);

        // Tap NEXT CONVERSION CARD
        final nextFinder = find.textContaining('NEXT CONVERSION CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
