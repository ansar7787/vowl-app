import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_practice_screen.dart';

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

  group('PhrasalVerbsPracticeScreen', () {
    testWidgets(
        'renders particle selection, validates choices, advances through scenario and typing exercises',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const PhrasalVerbsPracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PhrasalVerbsPracticeScreen), findsOneWidget);
      expect(find.text('PARTICLE SELECTION'), findsOneWidget);
      expect(
        find.textContaining("Slot the correct particle for the verb 'WAKE'"),
        findsOneWidget,
      );

      // Select option 'UP'
      final optionFinder = find.text('UP');
      await tester.ensureVisible(optionFinder);
      await tester.pumpAndSettle();
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Tap Check Particle
      final checkFinder = find.text('Check Particle');
      await tester.ensureVisible(checkFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkFinder);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('perfectly completes the context'),
        findsOneWidget,
      );
      expect(find.text('Next Exercise'), findsOneWidget);

      // Tap Next Exercise
      final nextFinder = find.text('Next Exercise');
      await tester.ensureVisible(nextFinder);
      await tester.pumpAndSettle();
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      // Exercise 2: Scenario Meaning
      expect(find.text('PARTICLE SELECTION'), findsOneWidget);
      expect(
        find.textContaining("Which particle transforms 'GET' into"),
        findsOneWidget,
      );

      // Select 'UP' option again
      final option2Finder = find.text('UP');
      await tester.ensureVisible(option2Finder);
      await tester.pumpAndSettle();
      await tester.tap(option2Finder);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Check Particle'));
      await tester.tap(find.text('Check Particle'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('means to physically rise out of bed'),
        findsOneWidget,
      );

      // Tap Next Exercise to Exercise 3 (typing)
      await tester.ensureVisible(find.text('Next Exercise'));
      await tester.tap(find.text('Next Exercise'));
      await tester.pumpAndSettle();

      // Exercise 3: Gap-Fill Recall
      expect(find.text('GAP-FILL RECALL'), findsOneWidget);
      final textInputFinder = find.byType(TextField);
      expect(textInputFinder, findsOneWidget);

      await tester.enterText(textInputFinder, 'on');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Check Particle'));
      await tester.tap(find.text('Check Particle'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("is the exact particle needed"),
        findsOneWidget,
      );
      expect(find.text('Enter Vault Mastery Arena 🏆'), findsOneWidget);
    });
  });
}
