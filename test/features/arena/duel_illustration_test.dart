import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/arena/presentation/widgets/duel_illustration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DuelIllustration Component Tests', () {
    testWidgets('renders in searching mode with semantic description', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 320,
                child: DuelIllustration(searching: true),
              ),
            ),
          ),
        ),
      );

      // Verify searching text '?' is present
      expect(find.text('?'), findsOneWidget);
      expect(find.byType(DuelIllustration), findsOneWidget);

      // Verify Semantics label for searching mode
      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label ==
                'Illustration: you and an opponent slot searching, ready for a 1 vs 1 word duel',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('renders in face-off mode (searching: false) with VS badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 320,
                child: DuelIllustration(searching: false),
              ),
            ),
          ),
        ),
      );

      // In settled mode, searching glyph is not rendered
      expect(find.text('?'), findsNothing);
      expect(find.byType(DuelIllustration), findsOneWidget);

      // Verify Semantics label for face-off mode
      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label ==
                'Illustration: two players facing off in a 1 vs 1 word duel with a trophy',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('renders in AI face-off mode (isOpponentAi: true) with AI semantics and mascot fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 320,
                child: DuelIllustration(searching: false, isOpponentAi: true),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DuelIllustration), findsOneWidget);

      // Verify Semantics label for AI opponent face-off mode
      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label ==
                'Illustration: you facing off against the Vowl AI in a 1 vs 1 word duel with a trophy',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('respects disableAnimationsOf without throwing or freezing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 320,
                  child: DuelIllustration(searching: false),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(DuelIllustration), findsOneWidget);
    });
  });
}
