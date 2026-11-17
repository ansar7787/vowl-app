import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_practice_screen.dart';

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

  group('FlashcardsPracticeScreen', () {
    testWidgets('renders active recall typing question, validates text, and gives feedback', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const FlashcardsPracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FlashcardsPracticeScreen), findsOneWidget);
      expect(find.text('⌨️ ACTIVE RECALL • FILL THE GAP'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter answer
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pumpAndSettle();

      // Check answer
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();

      expect(find.text('CORRECT'), findsOneWidget);
      expect(find.text('Next Exercise ➔'), findsOneWidget);
    });
  });
}
