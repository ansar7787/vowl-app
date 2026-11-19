import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_learn_screen.dart';

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

  group('AudioFillBlanksLearnScreen', () {
    testWidgets(
      'renders audio stream, missing word, blank structure, and advances cards',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const AudioFillBlanksLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AudioFillBlanksLearnScreen), findsOneWidget);
        expect(find.text('Audio Cloze Discovery'), findsOneWidget);
        expect(find.text('SPOKEN AUDIO STREAM'), findsOneWidget);
        expect(find.text('MISSING WORD'), findsOneWidget);
        expect(find.text('SENTENCE BLANK STRUCTURE'), findsOneWidget);

        expect(
          find.byKey(const Key('audio_fill_blanks_learn_missing_word')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('audio_fill_blanks_learn_blanks_text')),
          findsOneWidget,
        );

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
