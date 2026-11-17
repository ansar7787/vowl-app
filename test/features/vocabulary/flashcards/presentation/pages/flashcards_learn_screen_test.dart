import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_learn_screen.dart';

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

  group('FlashcardsLearnScreen', () {
    testWidgets('renders word card, pronunciation, tips, and responds to card tap', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const FlashcardsLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FlashcardsLearnScreen), findsOneWidget);
      expect(find.text('HELLO'), findsOneWidget);
      expect(find.text('Tap card to reveal definition'), findsOneWidget);

      // Tap card to reveal definition
      await tester.tap(find.text('HELLO'));
      await tester.pumpAndSettle();

      expect(find.text('A common greeting used when meeting someone or starting a conversation.'), findsOneWidget);
      expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
      expect(find.text('IN REAL CONVERSATION'), findsOneWidget);
    });
  });
}
