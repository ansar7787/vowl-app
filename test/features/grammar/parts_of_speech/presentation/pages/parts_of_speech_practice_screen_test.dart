import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_practice_screen.dart';

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

  group('PartsOfSpeechPracticeScreen', () {
    testWidgets(
      'renders target part of speech instruction, interactive word chips, and validates correct tap',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const PartsOfSpeechPracticeScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PartsOfSpeechPracticeScreen), findsOneWidget);
        expect(find.text('Find the Noun in this sentence'), findsOneWidget);

        // Tap a wrong word first ('baking')
        final wrongWordFinder = find.text('baking');
        await tester.ensureVisible(wrongWordFinder);
        await tester.tap(wrongWordFinder);
        await tester.pumpAndSettle();

        expect(find.text('Not quite. Try tapping another word!'), findsOneWidget);

        // Now tap the correct word ('kitchen')
        final correctWordFinder = find.text('kitchen');
        await tester.ensureVisible(correctWordFinder);
        await tester.tap(correctWordFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Kitchen'), findsOneWidget);
        expect(find.text('NEXT EXERCISE'), findsOneWidget);
      },
    );
  });
}
