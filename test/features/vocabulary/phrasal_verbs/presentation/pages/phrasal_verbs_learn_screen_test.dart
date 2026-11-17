import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_learn_screen.dart';

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

  group('PhrasalVerbsLearnScreen', () {
    testWidgets(
        'renders phrasal combination formula, core meaning, usage sentence, and advances to next verb',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const PhrasalVerbsLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PhrasalVerbsLearnScreen), findsOneWidget);
      expect(find.text('PHRASAL COMBINATION'), findsOneWidget);
      expect(find.text('VERB'), findsOneWidget);
      expect(find.text('PARTICLE'), findsOneWidget);
      expect(find.text('WAKE'), findsOneWidget);
      expect(find.text('UP'), findsWidgets);
      expect(find.text('CORE MEANING'), findsOneWidget);
      expect(find.text('AUTHENTIC USAGE'), findsOneWidget);
      expect(find.text('LITERAL VS FIGURATIVE'), findsOneWidget);
      expect(find.text('NATIVE SPEAKER PRO-TIP'), findsOneWidget);
      expect(find.text('Got It! Next Phrasal Verb'), findsOneWidget);

      // Advance to next verb
      await tester.tap(find.text('Got It! Next Phrasal Verb'));
      await tester.pumpAndSettle();

      // Verb 2: GET UP
      expect(find.text('GET'), findsOneWidget);
    });
  });
}
