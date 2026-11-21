import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/flashcards/data/services/flashcard_vault_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_vault_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
    );
  }

  final testEntries = [
    FlashcardVaultEntry(
      word: 'AUTHENTIC',
      level: 1,
      lastTestedAt: DateTime.now().subtract(const Duration(hours: 1)),
      repetitionCount: 2,
      stabilityHours: 48.0,
    ),
    FlashcardVaultEntry(
      word: 'GENUINE',
      level: 1,
      lastTestedAt: DateTime.now().subtract(const Duration(days: 5)),
      repetitionCount: 1,
      stabilityHours: 24.0,
    ),
  ];

  group('FlashcardVaultSheet', () {
    testWidgets('renders memory vault stats, entries, and filter tabs', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375 * 2, 812 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(FlashcardVaultSheet(initialEntries: testEntries)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Memory Vault'), findsOneWidget);
      expect(find.text('Ebbinghaus Spaced Repetition'), findsOneWidget);

      expect(find.text('MASTERED'), findsOneWidget);
      expect(find.text('DUE REVIEW'), findsOneWidget);
      expect(find.text('AVG HEALTH'), findsOneWidget);

      expect(find.text('AUTHENTIC'), findsOneWidget);
      expect(find.text('GENUINE'), findsOneWidget);

      // Tap Due for Review tab
      expect(find.textContaining('Due for Review'), findsOneWidget);
      await tester.tap(find.textContaining('Due for Review'));
      await tester.pumpAndSettle();

      // GENUINE (decayed after 5 days with 24h stability) should be in Due for Review
      expect(find.text('GENUINE'), findsOneWidget);
    });

    testWidgets('renders clean empty state when no entries are recorded', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375 * 2, 812 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(const FlashcardVaultSheet(initialEntries: [])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Memory Vault is Empty'), findsOneWidget);
      expect(find.textContaining('Complete the Mastery phase'), findsOneWidget);
    });
  });
}
