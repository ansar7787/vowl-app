import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_learn_screen.dart';

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

  group('PronounResolutionLearnScreen', () {
    testWidgets(
      'renders Ambiguity Tracer Engine, antecedent tracer badge, context passage, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const PronounResolutionLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PronounResolutionLearnScreen), findsOneWidget);
        expect(find.text('Ambiguity Tracer Engine'), findsOneWidget);
        expect(find.text('PRONOUN ➔ ANTECEDENT TRACER'), findsOneWidget);
        expect(find.text('she'), findsOneWidget);
        expect(find.text('Priya'), findsOneWidget);
        expect(find.text('CONTEXT PASSAGE'), findsOneWidget);
        expect(find.text('TRACER ANCHOR'), findsOneWidget);
        expect(find.text('GRAMMAR PRINCIPLE'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER INTUITION'), findsOneWidget);
        expect(find.textContaining('NEXT RESOLUTION CARD'), findsOneWidget);

        // Tap NEXT RESOLUTION CARD
        final nextFinder = find.textContaining('NEXT RESOLUTION CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Rule 2 of'), findsOneWidget);
      },
    );
  });
}
