import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_morpheme_formula.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('WordFormationMorphemeFormula', () {
    testWidgets('renders root and suffix breakdown for DECISION', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WordFormationMorphemeFormula(
            rootWord: 'DECIDE',
            formedWord: 'DECISION',
            targetRole: 'Noun',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MORPHOLOGICAL EQUATION'), findsOneWidget);
      expect(find.text('DECIDE'), findsOneWidget);
      expect(find.text('DECISION'), findsOneWidget);
      expect(find.text('SUFFIX'), findsOneWidget);
    });

    testWidgets('renders prefix, root, and suffix breakdown for INDECISIVE', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WordFormationMorphemeFormula(
            rootWord: 'DECIDE',
            formedWord: 'INDECISIVE',
            targetRole: 'Opposite',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PREFIX'), findsOneWidget);
      expect(find.text('IN-'), findsOneWidget);
      expect(find.text('DECIDE'), findsOneWidget);
      expect(find.text('INDECISIVE'), findsOneWidget);
    });
  });
}
