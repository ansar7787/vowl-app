import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/data/services/flashcard_vault_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/controllers/flashcard_controller.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_collocation_snap_card.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_precision_strike_view.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_speed_slam_view.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_vault_sheet.dart';

class MockHapticService extends Mock implements HapticService {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptic;
  late MockTtsService mockTts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockHaptic = MockHapticService();
    mockTts = MockTtsService();
    when(() => mockHaptic.selection()).thenAnswer((_) async {});
    when(() => mockHaptic.success()).thenAnswer((_) async {});
    when(() => mockHaptic.error()).thenAnswer((_) async {});
    when(() => mockHaptic.light()).thenAnswer((_) async {});
    when(() => mockTts.speak(any())).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerLazySingleton<HapticService>(() => mockHaptic);

    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerLazySingleton<TtsService>(() => mockTts);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('Pedagogical Competitor Elimination Upgrades', () {
    testWidgets(
      'Word Bank Quick-Review launches, restores memory health to 100%, and completes',
      (tester) async {
        tester.view.physicalSize = const Size(375 * 2, 812 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fadingEntry = FlashcardVaultEntry(
          word: 'AUTHENTIC',
          level: 1,
          lastTestedAt: DateTime.now().subtract(const Duration(days: 4)),
          repetitionCount: 1,
          stabilityHours: 24.0, // Decayed below 60%
        );

        await tester.pumpWidget(
          buildTestableWidget(
            FlashcardVaultSheet(initialEntries: [fadingEntry]),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Quick Review button is visible for fading words
        expect(find.byKey(const ValueKey('btn_quick_review')), findsOneWidget);
        expect(
          find.textContaining('Practice Fading Words (1)'),
          findsOneWidget,
        );

        // Tap Quick Review button
        await tester.tap(find.byKey(const ValueKey('btn_quick_review')));
        await tester.pumpAndSettle();

        // Verify Quick Review dialog opened with target word
        expect(find.text('AUTHENTIC'), findsWidgets);
        expect(find.textContaining('Retention:'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('btn_refresh_memory')),
          findsOneWidget,
        );

        // Tap Remembered to refresh memory
        await tester.ensureVisible(
          find.byKey(const ValueKey('btn_refresh_memory')),
        );
        await tester.tap(find.byKey(const ValueKey('btn_refresh_memory')));
        await tester.pump(const Duration(milliseconds: 300));

        // Memory restored badge
        expect(find.text('✨ Memory Restored to 100%!'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        // Verify review completed screen
        expect(find.text('Quick Review Complete! 🎉'), findsOneWidget);
        expect(find.byKey(const ValueKey('btn_review_done')), findsOneWidget);

        // Tap Back to Word Bank
        await tester.ensureVisible(
          find.byKey(const ValueKey('btn_review_done')),
        );
        await tester.tap(find.byKey(const ValueKey('btn_review_done')));
        await tester.pumpAndSettle();

        // Dialogue closed cleanly
        expect(find.text('Word Bank'), findsOneWidget);
      },
    );

    testWidgets(
      'FlashcardCollocationSnapCard displays 1-line instant explanation on wrong selection',
      (tester) async {
        int? selectedIndex;
        await tester.pumpWidget(
          buildTestableWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return FlashcardCollocationSnapCard(
                  collocationOptions: const [
                    'authentic cuisine',
                    'authentic weather',
                  ],
                  correctCollocationIndex: 0,
                  selectedCollocationIndex: selectedIndex,
                  hasCheckedCollocation: selectedIndex != null,
                  isDark: false,
                  onSelectCollocation: (idx) {
                    setState(() => selectedIndex = idx);
                  },
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap incorrect option (authentic weather)
        await tester.tap(find.byKey(const ValueKey('collocation_1')));
        await tester.pumpAndSettle();

        // 1-line instant explanation should be visible
        expect(
          find.textContaining('Natural phrasing: "authentic cuisine"'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'FlashcardSpeedSlamView displays 1-line instant explanation on incorrect collocation slam',
      (tester) async {
        tester.view.physicalSize = const Size(375 * 2, 812 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = FlashcardMasteryController(
          hapticService: mockHaptic,
          onSubmitResult: ({required isCorrect, required speedBonus}) {},
        );
        addTearDown(controller.dispose);

        const quest = VocabularyQuest(
          id: 'test_1',
          word: 'AUTHENTIC',
          instruction: 'Choose the natural phrase before the timer runs out!',
          difficulty: 1,
          collocations: ['authentic cuisine'],
          wrongCollocations: ['authentic weather'],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            FlashcardSpeedSlamView(
              quest: quest,
              controller: controller,
              isDark: false,
              onAdvanceToStage2: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap wrong collocation option (authentic weather)
        await tester.tap(find.text('authentic weather'));
        await tester.pumpAndSettle();

        // 1-line instant explanation should be visible
        expect(
          find.textContaining('Natural pairing: "authentic cuisine"'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'FlashcardPrecisionStrikeView displays 1-line instant explanation on incorrect candidate word',
      (tester) async {
        final controller = FlashcardMasteryController(
          hapticService: mockHaptic,
          onSubmitResult: ({required isCorrect, required speedBonus}) {},
        );
        addTearDown(controller.dispose);

        const quest = VocabularyQuest(
          id: 'test_strike',
          word: 'AUTHENTIC',
          instruction: 'Complete the sentence with the correct word.',
          difficulty: 1,
          contextSentence: 'The chef makes _____ Italian pasta.',
        );

        controller.isStage2.value = true;
        await tester.pumpWidget(
          buildTestableWidget(
            SingleChildScrollView(
              child: FlashcardPrecisionStrikeView(
                quest: quest,
                controller: controller,
                candidateWords: const ['AUTOMATIC', 'AUTHENTIC'],
                isDark: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap incorrect candidate word (candidate_0: AUTOMATIC)
        await tester.tap(find.byKey(const ValueKey('candidate_0')));
        await tester.pumpAndSettle();

        // 1-line instant explanation should be visible
        expect(
          find.textContaining(
            'Context fit: "AUTHENTIC" naturally fits the meaning of this sentence.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'FlashcardVaultSheet individual entry tile tap opens quick-review dialog',
      (tester) async {
        final entries = [
          FlashcardVaultEntry(
            word: 'SERENDIPITY',
            level: 3,
            lastTestedAt: DateTime.now().subtract(const Duration(days: 3)),
            stabilityHours: 24.0,
            repetitionCount: 1,
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(FlashcardVaultSheet(initialEntries: entries)),
        );
        await tester.pumpAndSettle();

        // Tap the entry tile
        await tester.tap(find.text('SERENDIPITY'));
        await tester.pumpAndSettle();

        // Quick-Review dialog opens for this single word
        expect(find.text('Word 1 of 1'), findsOneWidget);
        expect(find.byKey(const ValueKey('btn_refresh_memory')), findsOneWidget);
        expect(find.text('SERENDIPITY'), findsWidgets);
      },
    );
  });
}
