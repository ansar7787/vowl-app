import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/pages/punctuation_mastery_learn_screen.dart';

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

  group('PunctuationMasteryLearnScreen', () {
    testWidgets(
      'renders Punctuation Conductor, cadence card, rule explanation, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PunctuationMasteryLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PunctuationMasteryLearnScreen), findsOneWidget);
        expect(find.text('Punctuation Conductor'), findsOneWidget);
        expect(find.text('PUNCTUATION CADENCE & PAUSE'), findsOneWidget);
        expect(find.text('PUNCTUATED CADENCE'), findsOneWidget);
        expect(find.text('HOW PUNCTUATION GOVERNS CADENCE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT PUNCTUATION CARD'), findsOneWidget);

        // Tap NEXT PUNCTUATION CARD
        final nextFinder = find.textContaining('NEXT PUNCTUATION CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Punctuation 2 of'), findsOneWidget);
      },
    );
  });
}
