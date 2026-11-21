import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_category_tray.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child,
          ),
        ),
      ),
    );
  }

  group('TopicCategoryTray', () {
    testWidgets('renders category name, emoji, slots, and triggers callbacks', (tester) async {
      bool tapped = false;
      String? removedWord;
      String? tappedWord;

      await tester.pumpWidget(
        buildTestableWidget(
          TopicCategoryTray(
            categoryName: 'Intense Heat',
            emoji: '🔥',
            clue: 'Think of boiling liquids.',
            explanation: 'Words describing high heat and vapor.',
            targetCount: 3,
            placedWords: const ['Boiling'],
            isActive: true,
            isCompleted: false,
            accentColor: Colors.deepOrange,
            onTap: () => tapped = true,
            onRemoveWord: (w) => removedWord = w,
            onWordTap: (w) => tappedWord = w,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Intense Heat'), findsOneWidget);
      expect(find.byIcon(Icons.whatshot_rounded), findsOneWidget);
      expect(find.text('Boiling'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Tap on the category tray
      await tester.tap(find.text('Intense Heat'));
      await tester.pump();
      expect(tapped, isTrue);

      // Tap on the placed word chip
      await tester.tap(find.text('Boiling'));
      await tester.pump();
      expect(tappedWord, 'Boiling');

      // Tap on the cancel/remove icon
      final removeIcon = find.byIcon(Icons.cancel_rounded);
      expect(removeIcon, findsOneWidget);
      await tester.tap(removeIcon);
      await tester.pumpAndSettle();
      expect(removedWord, 'Boiling');
    });

    testWidgets('renders completed state with explanation and checkmark', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          TopicCategoryTray(
            categoryName: 'Intense Heat',
            emoji: '🔥',
            explanation: 'Words describing high heat and vapor.',
            collocations: const ['boiling water', 'scorching sun'],
            targetCount: 3,
            placedWords: const ['Boiling', 'Scorching', 'Steaming'],
            isActive: false,
            isCompleted: true,
            accentColor: Colors.deepOrange,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3/3'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Words describing high heat and vapor.'), findsOneWidget);
      expect(find.text('boiling water • scorching sun'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });
  });
}
