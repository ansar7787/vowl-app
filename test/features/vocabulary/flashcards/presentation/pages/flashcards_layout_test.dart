import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
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
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_game_body.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_back.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_front.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

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

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeVocabularyEvent extends Fake implements VocabularyEvent {}

class FakeVocabularyState extends Fake implements VocabularyState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<VocabularyState> vocabularyStreamController;

  VocabularyQuest createQuest({
    String id = 'quest_fc_1',
    String word = 'EPHEMERAL',
    String definition = 'Lasting for a very short time; transitory.',
    String explanation =
        'Commonly used in literature to describe fleeting moments of beauty.',
    String contextSentence =
        'The ephemeral glow of dusk faded quickly into night.',
    String usageExample = 'Her ephemeral fame was replaced by a quiet life.',
    String topicEmoji = '🌸',
    String hint = 'Think about something fleeting or temporary.',
    String instruction = 'Memorize the word and test your recall.',
    String prompt = 'Review this flashcard and test your recall.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.flashcards,
      word: word,
      definition: definition,
      explanation: explanation,
      contextSentence: contextSentence,
      usageExample: usageExample,
      topicEmoji: topicEmoji,
      hint: hint,
      instruction: instruction,
      prompt: prompt,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_fc_2',
    word: 'LUMINOUS',
    definition: 'Full of or shedding light; bright or shining.',
    explanation: 'From Latin luminosus, indicating radiating brightness.',
    contextSentence:
        'The luminous moon guided the sailors through the calm sea.',
    usageExample: 'Her luminous smile immediately brightened the room.',
    topicEmoji: '💡',
    hint: 'Relates to radiant light.',
  );

  final sampleMinimalQuest = createQuest(
    id: 'quest_fc_min',
    word: 'ZENITH',
    definition: 'The time at which something is most powerful.',
    explanation: '',
    contextSentence: '',
    usageExample: '',
    topicEmoji: '',
    hint: '',
  );

  final testLoadedState = VocabularyLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    wrongCount: 0,
    hintUsed: false,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeVocabularyEvent());
    registerFallbackValue(FakeVocabularyState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());
    registerFallbackValue(
      const FetchVocabularyQuests(gameType: GameSubtype.flashcards, level: 1),
    );
    registerFallbackValue(
      const FetchVocabularyQuests(gameType: GameSubtype.flashcards, level: 2),
    );
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;

    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    when(
      () => mockVocabularyBloc.stream,
    ).thenAnswer((_) => vocabularyStreamController.stream);

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());
    when(() => mockEconomyBloc.add(any())).thenReturn(null);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Flashcard Learner',
          hintCount: 3,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

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

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(
      () => mockSoundService.playTts(
        any(),
        speed: any(named: 'speed'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSoundService);

    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerSingleton<TtsService>(mockTtsService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    di.sl.registerSingleton<AppLogger>(mockAppLogger);

    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerSingleton<AdService>(mockAdService);

    if (di.sl.isRegistered<NetworkInfo>()) {
      di.sl.unregister<NetworkInfo>();
    }
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() {
    vocabularyStreamController.close();
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    if (di.sl.isRegistered<NetworkInfo>()) {
      di.sl.unregister<NetworkInfo>();
    }
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    VocabularyState? state,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.dark,
    int level = 2,
    double textScale = 1.0,
    bool disableAnimations = true,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final targetState = state ?? testLoadedState;
    when(() => mockVocabularyBloc.state).thenReturn(targetState);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
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
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
                disableAnimations: disableAnimations,
              ),
              child: Scaffold(
                body: FlashcardsScreen(
                  level: level,
                  gameType: GameSubtype.flashcards,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Group 1: Initial Screen Layout & Structural Hierarchy', () {
    testWidgets('renders FlashcardsScreen and initializes fetch request', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(FlashcardsScreen), findsOneWidget);
      expect(find.byType(FlashcardGameBody), findsOneWidget);
      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(find.byType(FlashcardSwipeBack), findsNothing);

      verify(
        () => mockVocabularyBloc.add(
          const FetchVocabularyQuests(
            gameType: GameSubtype.flashcards,
            level: 2,
          ),
        ),
      ).called(1);
    });

    testWidgets('displays topic emoji container on front card', (tester) async {
      await pumpScreen(tester);

      expect(find.text('🌸'), findsOneWidget);
    });

    testWidgets('displays custom hint on front card when available', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        find.text('Think about something fleeting or temporary.'),
        findsOneWidget,
      );
    });

    testWidgets('falls back to default instruction when hint is null', (
      tester,
    ) async {
      final stateWithNullHint = VocabularyLoaded(
        quests: [
          createQuest(id: 'q_no_hint', hint: '', instruction: 'Memorize now.'),
        ],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        wrongCount: 0,
        hintUsed: false,
        isFinalFailure: false,
      );

      await pumpScreen(tester, state: stateWithNullHint);

      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(find.text('Memorize now.'), findsWidgets);
    });

    testWidgets('displays instruction banner and tap-to-reveal action prompt', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('TAP TO REVEAL'), findsOneWidget);
      expect(find.byIcon(Icons.touch_app_rounded), findsWidgets);
    });
  });

  group('Group 2: Card Flip Mechanics & Visual Transitions', () {
    testWidgets('tapping card flips from front face to back face', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(find.byType(FlashcardSwipeBack), findsNothing);

      // Tap card
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FlashcardSwipeBack), findsOneWidget);
      verify(() => mockHapticService.light()).called(1);
    });

    testWidgets('reveals target word, definition and labels on back card', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('EPHEMERAL'), findsOneWidget);
      expect(find.text('DEFINITION'), findsOneWidget);
      expect(
        find.text('Lasting for a very short time; transitory.'),
        findsOneWidget,
      );
    });

    testWidgets('reveals DID YOU KNOW section with explanation', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('DID YOU KNOW?'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(
        find.text(
          'Commonly used in literature to describe fleeting moments of beauty.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('reveals EXAMPLE section with primary and usage examples', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('EXAMPLE'), findsOneWidget);
      expect(
        find.text('The ephemeral glow of dusk faded quickly into night.'),
        findsOneWidget,
      );
      expect(
        find.text('Her ephemeral fame was replaced by a quiet life.'),
        findsOneWidget,
      );
    });

    testWidgets('action buttons update to AGAIN and GOT IT when flipped', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('TAP TO REVEAL'), findsOneWidget);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('AGAIN'), findsOneWidget);
      expect(find.text('GOT IT'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_double_arrow_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_double_arrow_right_rounded), findsOneWidget);
    });

    testWidgets('instruction banner switches to swipe instruction when flipped', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('SWIPE LEFT (AGAIN) OR RIGHT (GOT IT)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.swipe_rounded), findsOneWidget);
    });

    testWidgets('tapping back card flips it back to front face', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip to back
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FlashcardSwipeBack), findsOneWidget);

      // Flip back to front
      await tester.tap(find.byType(FlashcardSwipeBack));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
    });
  });

  group('Group 3: Swipe Gesture Mechanics & Directional Detection', () {
    testWidgets('horizontal drag updates offset and angle with selection haptics', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip to back first
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Perform a drag update
      await tester.drag(find.byType(FlashcardSwipeBack), const Offset(60, 0));
      await tester.pump();

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('dragging right past threshold submits correct answer', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip to back
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Drag right past 200px threshold
      await tester.drag(find.byType(FlashcardSwipeBack), const Offset(250, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('dragging left past threshold submits wrong answer', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip to back
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Drag left past 200px threshold
      await tester.drag(find.byType(FlashcardSwipeBack), const Offset(-250, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('dragging below threshold snaps card back without submitting', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip to back
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Drag slightly (below 90 threshold)
      await tester.drag(find.byType(FlashcardSwipeBack), const Offset(40, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockVocabularyBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockVocabularyBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('drag gesture is ignored when card is on front face', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Dragging front card should not trigger submission
      await tester.drag(find.byType(FlashcardSwipeFront), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockVocabularyBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockVocabularyBloc.add(const SubmitAnswer(false)));
    });
  });

  group('Group 4: Action Buttons Tap Mechanics & State Handling', () {
    testWidgets('tapping GOT IT button submits correct answer', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip to back
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap GOT IT
      await tester.tap(find.text('GOT IT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('tapping AGAIN button submits wrong answer', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip to back
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap AGAIN
      await tester.tap(find.text('AGAIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('subsequent drags or taps are ignored once answered', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // First submit
      await tester.tap(find.text('GOT IT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Second attempt to tap AGAIN
      await tester.tap(find.text('AGAIN'), warnIfMissed: false);
      await tester.pump();

      // Only one submit
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
      verifyNever(() => mockVocabularyBloc.add(const SubmitAnswer(false)));
    });
  });

  group('Group 5: Hint System & Audio (TTS) Lifecycle', () {
    testWidgets('tapping header hint button auto-flips card and marks hint active', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(FlashcardSwipeFront), findsOneWidget);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FlashcardSwipeBack), findsOneWidget);
    });

    testWidgets('hint timer auto-flips card back to front after 4 seconds', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Request hint
      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FlashcardSwipeBack), findsOneWidget);

      // Elapse 4.2 seconds and allow reverse flip animation to finish
      await tester.pump(const Duration(milliseconds: 4200));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
    });

    testWidgets('tapping TTS speaker button on back card invokes speak', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final volumeIcon = find.byIcon(Icons.volume_up_rounded);
      expect(volumeIcon, findsOneWidget);

      await tester.tap(volumeIcon);
      await tester.pump();

      verify(() => mockTtsService.speak('EPHEMERAL')).called(greaterThanOrEqualTo(1));
    });

    testWidgets('back card auto-speaks word after 200ms delay', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      // Pump 500ms to complete flip animation and mount FlashcardSwipeBack (starting 200ms timer)
      await tester.pump(const Duration(milliseconds: 500));
      // Pump 300ms to elapse the 200ms TTS timer
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockTtsService.speak('EPHEMERAL')).called(1);
    });
  });

  group('Group 6: State Progression, Dialogs & Error Handling', () {
    testWidgets('displays GameShimmerLoading when state is uninitialized', (
      tester,
    ) async {
      const emptyState = VocabularyInitial();
      await pumpScreen(tester, state: emptyState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('displays ErrorScaffold and allows retrying on VocabularyError', (
      tester,
    ) async {
      const errorState = VocabularyError('Failed to load flashcard quests');
      await pumpScreen(tester, state: errorState);

      expect(find.text('Failed to load flashcard quests'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      final retryBtn = find.text('TRY AGAIN');
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pump();

      verify(
        () => mockVocabularyBloc.add(
          const FetchVocabularyQuests(
            gameType: GameSubtype.flashcards,
            level: 2,
          ),
        ),
      ).called(2); // 1 from initState, 1 from retry
    });

    testWidgets('renders GameFeedbackCard on correct answer with CONTINUE button', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip and answer
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('GOT IT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Emit loaded state with correct answer
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      vocabularyStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('renders GameFeedbackCard on wrong answer with pedagogical feedback', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip and answer wrong
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('AGAIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final wrongState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
        wrongCount: 1,
      );
      vocabularyStreamController.add(wrongState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsWidgets);
    });

    testWidgets('advancing to next question resets card to unflipped state', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Flip and answer
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FlashcardSwipeBack), findsOneWidget);

      // Advance to quest 2
      final nextQuestState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      vocabularyStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Card should be reset to front face for the new question
      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(find.text('LUMINOUS'), findsNothing);
      expect(find.text('💡'), findsOneWidget);
    });

    testWidgets('VocabularyGameComplete state triggers game completion', (
      tester,
    ) async {
      await pumpScreen(tester);

      const completeState = VocabularyGameComplete(
        xpEarned: 100,
        coinsEarned: 50,
        questCount: 2,
      );
      vocabularyStreamController.add(completeState);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VOCAB MASTERY!'), findsOneWidget);

      Navigator.of(tester.element(find.text('VOCAB MASTERY!'))).pop();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('Group 7: Viewport Responsiveness, Theming & Accessibility', () {
    testWidgets('renders on compact mobile screen (320x568) without overflow', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(320, 568));

      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Flip on compact mobile
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FlashcardSwipeBack), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on tablet screen (768x1024) with responsive layout', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(768, 1024));

      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Flip on tablet
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FlashcardSwipeBack), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in landscape orientation (800x480) without overflow', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(800, 480));

      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts to high text scaling (1.5x) gracefully', (
      tester,
    ) async {
      await pumpScreen(tester, textScale: 1.5);

      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FlashcardSwipeBack), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in light theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Semantics information for screen readers', (
      tester,
    ) async {
      await pumpScreen(tester);

      final frontSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('TAP TO REVEAL'),
      );
      expect(frontSemantics, findsWidgets);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final backSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('Word: EPHEMERAL'),
      );
      expect(backSemantics, findsWidgets);
    });

    testWidgets('handles minimal quest data gracefully without crash', (
      tester,
    ) async {
      final minimalState = VocabularyLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        wrongCount: 0,
        hintUsed: false,
        isFinalFailure: false,
      );

      await pumpScreen(tester, state: minimalState);
      expect(find.byType(FlashcardSwipeFront), findsOneWidget);

      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FlashcardSwipeBack), findsOneWidget);
      expect(find.text('ZENITH'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

