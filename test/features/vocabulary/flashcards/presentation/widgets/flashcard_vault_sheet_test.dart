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

      expect(find.text('Word Bank'), findsOneWidget);
      expect(find.text("Review words you've learned"), findsOneWidget);

      expect(find.text('MASTERED'), findsOneWidget);
      expect(find.text('TO REVIEW'), findsOneWidget);
      expect(find.text('RETENTION'), findsOneWidget);

      expect(find.text('AUTHENTIC'), findsOneWidget);
      expect(find.text('GENUINE'), findsOneWidget);

      // Tap Needs Review tab
      expect(find.textContaining('Needs Review'), findsOneWidget);
      await tester.tap(find.textContaining('Needs Review'));
      await tester.pumpAndSettle();

      // GENUINE (decayed after 5 days with 24h stability) should be in Needs Review
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

      expect(find.text('Your Word Bank is Empty'), findsOneWidget);
      expect(
        find.textContaining('Master words to add them here'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders cleanly without overflow in landscape mode (640x306)',
      (tester) async {
        tester.view.physicalSize = const Size(640, 306);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget(FlashcardVaultSheet(initialEntries: testEntries)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Word Bank'), findsOneWidget);
        expect(find.text('MASTERED'), findsOneWidget);
        expect(find.text('AUTHENTIC'), findsOneWidget);
      },
    );
  });
}
