import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/pages/sentence_order_reading_screen.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_capstone.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_instruction.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_stone_slab.dart';

class MockReadingBloc extends MockBloc<ReadingEvent, ReadingState>
    implements ReadingBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class FakeReadingEvent extends Fake implements ReadingEvent {}

class FakeReadingState extends Fake implements ReadingState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReadingBloc mockReadingBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  setUpAll(() {
    registerFallbackValue(FakeReadingEvent());
    registerFallbackValue(FakeReadingState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const ReadingHintUsed());
  });

  const testOrderQuest = ReadingQuest(
    id: 'RDG_SENTENCEORDER_L1_Q1',
    instruction: 'Reconstruct the logical timeline of the invention.',
    difficulty: 1,
    subtype: GameSubtype.sentenceOrderReading,
    shuffledSentences: [
      'Finally, mass production brought the device into homes everywhere.',
      'Initially, scientists discovered the basic underlying principle.',
      'Subsequently, engineers constructed a working laboratory prototype.',
    ],
    correctOrder: [1, 2, 0], // Chronological: Initially (1), Subsequently (2), Finally (0)
    transitionWords: ['Initially', 'Subsequently', 'Finally'],
    hint: 'Pay close attention to chronological transition words.',
    explanation:
        'The timeline progresses from discovery, to prototype, to mass production.',
  );

  const testNextOrderQuest = ReadingQuest(
    id: 'RDG_SENTENCEORDER_L1_Q2',
    instruction: 'Order the steps of cellular respiration.',
    difficulty: 1,
    subtype: GameSubtype.sentenceOrderReading,
    shuffledSentences: [
      'Second, pyruvate enters the mitochondrion.',
      'First, glucose is broken down via glycolysis.',
      'Third, the electron transport chain generates ATP.',
    ],
    correctOrder: [1, 0, 2],
    transitionWords: ['First', 'Second', 'Third'],
    hint: 'Trace the biochemical pathways step by step.',
  );

  const testLoadedState = ReadingLoaded(
    quests: [testOrderQuest, testNextOrderQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testAnsweredState = ReadingLoaded(
    quests: [testOrderQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.correct,
  );

  setUp(() async {
    mockReadingBloc = MockReadingBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_sentenceOrderReading': true,
    });

    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));

    when(() => mockReadingBloc.state).thenReturn(testLoadedState);
    when(() => mockReadingBloc.stream)
        .thenAnswer((_) => const Stream<ReadingState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Test Explorer',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
        isKids: any(named: 'isKids'),
      ),
    ).thenAnswer((_) async {});

    di.sl.reset();

    di.sl.registerLazySingleton<HapticService>(() => mockHapticService);
    di.sl.registerLazySingleton<SoundService>(() => mockSoundService);
    di.sl.registerLazySingleton<TtsService>(() => mockTtsService);
    di.sl.registerLazySingleton<LocaleService>(() => mockLocaleService);
    di.sl.registerLazySingleton<AppLogger>(() => mockLogger);
    di.sl.registerLazySingleton<AnalyticsService>(() => mockAnalyticsService);
    di.sl.registerLazySingleton<AdService>(() => mockAdService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    di.sl.reset();
  });

  Future<void> pumpSentenceOrder(
    WidgetTester tester, {
    ReadingState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockReadingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ReadingBloc>.value(value: mockReadingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: SentenceOrderReadingScreen(
              level: level,
              gameType: GameSubtype.sentenceOrderReading,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Helper to arrange sentences into the target correct order via tap-to-swap
  Future<void> arrangeChronologicalOrder(WidgetTester tester) async {
    final targetOrder = [
      'Initially, scientists discovered the basic underlying principle.',
      'Subsequently, engineers constructed a working laboratory prototype.',
      'Finally, mass production brought the device into homes everywhere.',
    ];

    for (int targetIdx = 0; targetIdx < targetOrder.length; targetIdx++) {
      final slabs = tester
          .widgetList<SentenceOrderReadingStoneSlab>(
            find.byType(SentenceOrderReadingStoneSlab),
          )
          .toList();
      final currentIdx = slabs.indexWhere((s) => s.text == targetOrder[targetIdx]);
      if (currentIdx != targetIdx) {
        // Tap currentIdx slab to select
        await tester.tap(find.byWidget(slabs[currentIdx]));
        await tester.pump();
        // Tap targetIdx slab to swap
        final updatedSlabs = tester
            .widgetList<SentenceOrderReadingStoneSlab>(
              find.byType(SentenceOrderReadingStoneSlab),
            )
            .toList();
        await tester.tap(find.byWidget(updatedSlabs[targetIdx]));
        await tester.pump();
      }
    }
  }

  group('SentenceOrderReadingScreen Layout & Interactions', () {
    testWidgets('1. Initial layout renders instruction, stone slabs, and check order button', (
      tester,
    ) async {
      await pumpSentenceOrder(tester);

      expect(find.byType(SentenceOrderReadingInstruction), findsOneWidget);
      expect(
        find.text('Reconstruct the logical timeline of the invention.'),
        findsOneWidget,
      );

      expect(find.byType(SentenceOrderReadingStoneSlab), findsNWidgets(3));
      expect(find.byType(SentenceOrderReadingCapstone), findsOneWidget);
      expect(find.text('Check Order'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(3));
    });

    testWidgets('2. Transition words render with highlighted spans', (tester) async {
      await pumpSentenceOrder(tester);

      final slabWidgets = tester
          .widgetList<SentenceOrderReadingStoneSlab>(
            find.byType(SentenceOrderReadingStoneSlab),
          )
          .toList();

      expect(slabWidgets.length, 3);
      for (final slab in slabWidgets) {
        expect(slab.transitionRegex, isNotNull);
      }
    });

    testWidgets('3. Tapping a stone slab selects it and triggers selection haptic', (
      tester,
    ) async {
      await pumpSentenceOrder(tester);

      final firstSlabFinder = find.byType(SentenceOrderReadingStoneSlab).first;
      await tester.tap(firstSlabFinder);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);

      final updatedSlab = tester.widget<SentenceOrderReadingStoneSlab>(
        firstSlabFinder,
      );
      expect(updatedSlab.isSelected, isTrue);
    });

    testWidgets('4. Tapping the selected stone slab again deselects it', (
      tester,
    ) async {
      await pumpSentenceOrder(tester);

      final firstSlabFinder = find.byType(SentenceOrderReadingStoneSlab).first;
      await tester.tap(firstSlabFinder);
      await tester.pump();

      expect(
        tester.widget<SentenceOrderReadingStoneSlab>(firstSlabFinder).isSelected,
        isTrue,
      );

      await tester.tap(firstSlabFinder);
      await tester.pump();

      expect(
        tester.widget<SentenceOrderReadingStoneSlab>(firstSlabFinder).isSelected,
        isFalse,
      );
      verify(() => mockHapticService.selection()).called(2);
    });

    testWidgets('5. Tapping another stone slab while one is selected swaps their positions', (
      tester,
    ) async {
      await pumpSentenceOrder(tester);

      final initialSlabs = tester
          .widgetList<SentenceOrderReadingStoneSlab>(
            find.byType(SentenceOrderReadingStoneSlab),
          )
          .toList();
      final textAt0 = initialSlabs[0].text;
      final textAt1 = initialSlabs[1].text;

      // Select first slab
      await tester.tap(find.byWidget(initialSlabs[0]));
      await tester.pump();

      // Tap second slab to swap
      final slabsAfterSelect = tester
          .widgetList<SentenceOrderReadingStoneSlab>(
            find.byType(SentenceOrderReadingStoneSlab),
          )
          .toList();
      await tester.tap(find.byWidget(slabsAfterSelect[1]));
      await tester.pump();

      final swappedSlabs = tester
          .widgetList<SentenceOrderReadingStoneSlab>(
            find.byType(SentenceOrderReadingStoneSlab),
          )
          .toList();
      expect(swappedSlabs[0].text, equals(textAt1));
      expect(swappedSlabs[1].text, equals(textAt0));
      expect(swappedSlabs[0].isSelected, isFalse);
      expect(swappedSlabs[1].isSelected, isFalse);
    });

    testWidgets('6. Reorderable list onReorder shifts item positions and triggers selection haptic', (
      tester,
    ) async {
      await pumpSentenceOrder(tester);

      final reorderableList = tester.widget<SliverReorderableList>(
        find.byType(SliverReorderableList),
      );

      final initialSlabs = tester
          .widgetList<SentenceOrderReadingStoneSlab>(
            find.byType(SentenceOrderReadingStoneSlab),
          )
          .toList();
      final movedText = initialSlabs[0].text;

      reorderableList.onReorder(0, 2);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
      final updatedSlabs = tester
          .widgetList<SentenceOrderReadingStoneSlab>(
            find.byType(SentenceOrderReadingStoneSlab),
          )
          .toList();
      expect(updatedSlabs[1].text, equals(movedText));
    });

    testWidgets('7. Submitting initial scrambled order dispatches SubmitAnswer(false)', (
      tester,
    ) async {
      await pumpSentenceOrder(tester);

      final capstone = find.byType(SentenceOrderReadingCapstone);
      expect(capstone, findsOneWidget);

      await tester.tap(capstone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.heavy()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('8. Arranging into correct order and tapping capstone dispatches SubmitAnswer(true)', (
      tester,
    ) async {
      await pumpSentenceOrder(tester);

      await arrangeChronologicalOrder(tester);

      final capstone = find.byType(SentenceOrderReadingCapstone);
      await tester.tap(capstone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.heavy()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('9. Interaction lockout prevents changes once answered', (
      tester,
    ) async {
      final stateController = StreamController<ReadingState>.broadcast();
      when(() => mockReadingBloc.stream).thenAnswer((_) => stateController.stream);

      await pumpSentenceOrder(tester);

      // Transition to answered state
      stateController.add(testAnsweredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Lock capstone should be hidden
      expect(find.byType(SentenceOrderReadingCapstone), findsNothing);

      // Tapping slabs should NOT select or trigger selection haptic
      clearInteractions(mockHapticService);
      final firstSlab = find.byType(SentenceOrderReadingStoneSlab).first;
      await tester.tap(firstSlab, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockHapticService.selection());
      expect(
        tester.widget<SentenceOrderReadingStoneSlab>(firstSlab).isSelected,
        isFalse,
      );

      await stateController.close();
    });

    testWidgets('10. Continue button dispatches NextQuestion event', (tester) async {
      await pumpSentenceOrder(tester, state: testAnsweredState);
      await tester.pump(const Duration(milliseconds: 600));

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockReadingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('11. Hint button in header dispatches ReadingHintUsed', (tester) async {
      await pumpSentenceOrder(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockReadingBloc.add(any(that: isA<ReadingHintUsed>()))).called(2);
    });

    testWidgets('12. Shimmer loading renders when state is ReadingInitial', (
      tester,
    ) async {
      await pumpSentenceOrder(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SentenceOrderReadingStoneSlab), findsNothing);
    });

    testWidgets('13. Game briefing layer renders on Level 1 and dismisses on action', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_sentenceOrderReading': false,
      });

      await pumpSentenceOrder(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('STRUCTURE ARCHITECT'), findsOneWidget);
      final startBtn = find.text('REBUILD FLOW');
      expect(startBtn, findsOneWidget);

      await tester.ensureVisible(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
      expect(find.byType(SentenceOrderReadingStoneSlab), findsNWidgets(3));
    });

    testWidgets('14. Dark theme renders cleanly without contrast issues', (
      tester,
    ) async {
      await pumpSentenceOrder(tester, themeMode: ThemeMode.dark);

      final instruction = find.byType(SentenceOrderReadingInstruction);
      expect(instruction, findsOneWidget);

      final slabs = tester.widgetList<SentenceOrderReadingStoneSlab>(
        find.byType(SentenceOrderReadingStoneSlab),
      );
      for (final slab in slabs) {
        expect(slab.isDark, isTrue);
      }
    });

    testWidgets('15. Small screen (320x640) renders without layout overflow', (
      tester,
    ) async {
      await pumpSentenceOrder(tester, width: 320, height: 640);

      expect(tester.takeException(), isNull);
      expect(find.byType(SentenceOrderReadingStoneSlab), findsNWidgets(3));
      expect(find.byType(SentenceOrderReadingCapstone), findsOneWidget);
    });

    testWidgets('16. Question reset resets order and clears selection', (
      tester,
    ) async {
      final stateController = StreamController<ReadingState>.broadcast();
      when(() => mockReadingBloc.stream).thenAnswer((_) => stateController.stream);

      await pumpSentenceOrder(tester);

      // Select first slab
      final firstSlab = find.byType(SentenceOrderReadingStoneSlab).first;
      await tester.tap(firstSlab);
      await tester.pump();
      expect(
        tester.widget<SentenceOrderReadingStoneSlab>(firstSlab).isSelected,
        isTrue,
      );

      // Reset question via new quest loaded
      stateController.add(
        const ReadingLoaded(
          quests: [testNextOrderQuest],
          currentIndex: 0,
          livesRemaining: 3,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);

      await stateController.close();
    });
  });
}

