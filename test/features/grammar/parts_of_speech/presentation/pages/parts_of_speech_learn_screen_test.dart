import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_learn_screen.dart';

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

  group('PartsOfSpeechLearnScreen', () {
    testWidgets(
      'renders concept badge, sentence card, role explanation, and advances to next concept',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const PartsOfSpeechLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PartsOfSpeechLearnScreen), findsOneWidget);
        expect(find.text('HOW IT FUNCTIONS'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT CONCEPT'), findsOneWidget);

        // Tap NEXT CONCEPT
        final nextFinder = find.textContaining('NEXT CONCEPT');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Concept 2 of'), findsOneWidget);
      },
    );
  });
}
