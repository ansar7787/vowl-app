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
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
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
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_screen.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/instruction_panel.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/morph_injection_rail.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/reaction_core.dart';

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
    String id = 'quest_wf_1',
    String word = 'create',
    String rootWord = 'create',
    String correctAnswer = 'creation',
    List<String> options = const ['-tion', '-ment', '-able', '-ful'],
    String hint = 'The process of bringing something into existence.',
    String instruction = 'Form the correct word by attaching the right affix.',
    String explanation = 'Creation is the noun form of create.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.wordFormation,
      word: word,
      rootWord: rootWord,
      correctAnswer: correctAnswer,
      options: options,
      hint: hint,
      instruction: instruction,
      explanation: explanation,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_wf_2',
    word: 'develop',
    rootWord: 'develop',
    correctAnswer: 'development',
    options: ['-ment', '-ness', '-ity', '-tion'],
    hint: 'The process of developing or being developed.',
    instruction: 'Form the word by choosing the correct affix.',
    explanation: 'Development is formed by adding -ment to develop.',
  );

  final sampleMinimalQuest = const VocabularyQuest(
    id: 'quest_wf_minimal',
    type: QuestType.vocabulary,
    subtype: GameSubtype.wordFormation,
    word: 'act',
    rootWord: 'act',
    correctAnswer: 'action',
    options: ['-tion', '-ment'],
    instruction: 'Form the word.',
    difficulty: 1,
  );

  final testLoadedState = VocabularyLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
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
      const FetchVocabularyQuests(
        gameType: GameSubtype.wordFormation,
        level: 2,
      ),
    );
    registerFallbackValue(const EconomyAddCoinsRequested(10));
  });

  setUp(() async {
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

    // Haptic mocks
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    // Sound mocks
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

    // TTS mock
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_wf',
          email: 'wf@vowl.app',
          displayName: 'Morphologist',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    // Economy mock
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    // Network mock
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Vocabulary Bloc setup
    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    when(
      () => mockVocabularyBloc.stream,
    ).thenAnswer((_) => vocabularyStreamController.stream);

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await vocabularyStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
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
                body: WordFormationScreen(
                  level: level,
                  gameType: GameSubtype.wordFormation,
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

  Future<void> advanceToPhase2(WidgetTester tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('-TION').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  group('Group 1: Component Rendering & Initial State', () {
    testWidgets('1. renders GameShimmerLoading when state has no quest', (tester) async {
      await pumpScreen(tester, state: const VocabularyInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('2. renders InstructionPanel with instruction text and hint definition', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(InstructionPanel), findsOneWidget);
      expect(find.text(sampleQuest1.hint!), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    });

    testWidgets('3. renders ReactionCore displaying uppercase root word', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(ReactionCore), findsOneWidget);
      expect(find.text('CREATE'), findsOneWidget);
    });

    testWidgets('4. renders all affix option chips in MorphInjectionRail', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(MorphInjectionRail), findsNWidgets(4));
      expect(find.text('-TION'), findsOneWidget);
      expect(find.text('-MENT'), findsOneWidget);
      expect(find.text('-ABLE'), findsOneWidget);
      expect(find.text('-FUL'), findsOneWidget);
    });

    testWidgets('5. renders header controls including QuestHintButton', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(QuestHintButton), findsOneWidget);
    });

    testWidgets('6. initial state has phase 2 TypeToConfirmOverlay not displayed', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(TypeToConfirmOverlay), findsNothing);
    });
  });

  group('Group 2: Phase 1 Morph Selection Mechanics', () {
    testWidgets('7. tapping correct affix chip triggers success haptic and advances to Phase 2', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('-TION').first);
      await tester.pump();

      verify(() => mockHapticService.success()).called(1);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });

    testWidgets('8. tapping incorrect affix triggers wrong sound, error haptic, and dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('-MENT').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.error()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isFalse)),
        ),
      ).called(1);
    });

    testWidgets('9. sliding handle past hover threshold (> 0.2) triggers hover and selection haptic', (tester) async {
      await pumpScreen(tester);

      await tester.drag(find.text('-TION').first, const Offset(150, 0));
      await tester.pump();

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('10. dragging handle all the way (>= 0.95) fuses and advances to phase 2', (tester) async {
      await pumpScreen(tester);

      // Drag completely across the rail
      await tester.drag(find.text('-TION').first, const Offset(300, 0));
      await tester.pump();

      verify(() => mockHapticService.success()).called(1);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });

    testWidgets('11. morph selection is blocked after stage 1 is passed', (tester) async {
      await advanceToPhase2(tester);

      // Try tapping another option chip
      await tester.tap(find.text('-MENT').first, warnIfMissed: false);
      await tester.pump();

      // No new sound or answer submission should be triggered
      verifyNever(() => mockSoundService.playWrong());
    });

    testWidgets('12. ReactionCore updates root word to uppercase target word upon advancing', (tester) async {
      await advanceToPhase2(tester);

      expect(find.text('CREATION'), findsWidgets);
    });
  });

  group('Group 3: Phase 2 Confirmation Mechanics (TypeToConfirmOverlay)', () {
    testWidgets('13. TypeToConfirmOverlay renders expected uppercase text prompt', (tester) async {
      await advanceToPhase2(tester);

      final overlayFinder = find.byType(TypeToConfirmOverlay);
      expect(overlayFinder, findsOneWidget);

      final overlay = tester.widget<TypeToConfirmOverlay>(overlayFinder);
      expect(overlay.expectedText, equals('creation'));
      expect(find.textContaining('CREATION'), findsWidgets);
    });

    testWidgets('14. confirming stage 2 via onConfirmed triggers sound, haptic, and SubmitAnswer(true)', (tester) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();

      verify(() => mockSoundService.playCorrect()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(2));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isTrue)),
        ),
      ).called(1);
    });

    testWidgets('15. skipping stage 2 via onSkipped dispatches SubmitAnswer(false)', (tester) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onSkipped();
      await tester.pump();

      verify(() => mockSoundService.playWrong()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.error()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isFalse)),
        ),
      ).called(1);
    });

    testWidgets('16. bypassing stage 2 via onBypassed dispatches SubmitAnswer(true)', (tester) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onBypassed?.call();
      await tester.pump();

      verify(() => mockSoundService.playCorrect()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isTrue)),
        ),
      ).called(1);
    });

    testWidgets('17. typing correct target word in TextField and submitting confirms stage 2', (tester) async {
      await advanceToPhase2(tester);

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'creation');
      await tester.pump();

      final submitButton = find.text('SUBMIT');
      expect(submitButton, findsOneWidget);

      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isTrue)),
        ),
      ).called(1);
    });

    testWidgets('18. typing gibberish or incorrect word shows mismatch diff', (tester) async {
      await advanceToPhase2(tester);

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'xyzqwert');
      await tester.pump();

      final submitButton = find.text('SUBMIT');
      await tester.tap(submitButton);
      await tester.pump();

      // SubmitAnswer should not be called with true
      verifyNever(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isTrue)),
        ),
      );
    });
  });

  group('Group 4: Hint System & Guidance', () {
    testWidgets('19. tapping hint button calls TtsService.speak with target word', (tester) async {
      await pumpScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockTtsService.speak('creation')).called(1);
      verify(() => mockVocabularyBloc.add(any(that: isA<VocabularyHintUsed>()))).called(1);
    });

    testWidgets('20. tapping hint highlights correct affix in ReactionCore and sets hovering index', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();

      // Hovering index 0 sets activeSuffix to -tion, displaying + -TION in ReactionCore
      expect(find.text('-TION'), findsWidgets);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('21. hint highlight auto-clears after timer expiry', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Advance past 2.seconds hint timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });

    testWidgets('22. QuestHintButton is hidden when question is answered', (tester) async {
      await pumpScreen(tester);

      // Fail question
      await tester.tap(find.text('-MENT').first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(QuestHintButton), findsNothing);
    });
  });

  group('Group 5: Answer State, Feedback & Question Advancement', () {
    testWidgets('23. displays GameFeedbackCard with explanation when answered correctly', (tester) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text(sampleQuest1.explanation!), findsOneWidget);
    });

    testWidgets('24. displays GameFeedbackCard with failure title when answered incorrectly', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('-MENT').first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('NOT QUITE!'), findsOneWidget);
    });

    testWidgets('25. tapping continue button in GameFeedbackCard dispatches NextQuestion()', (tester) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump();

      verify(() => mockVocabularyBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('26. transitions cleanly from quest 1 to quest 2 and resets state', (tester) async {
      await pumpScreen(tester);

      expect(find.text('CREATE'), findsOneWidget);

      final nextState = VocabularyLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
      );
      vocabularyStreamController.add(nextState);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('DEVELOP'), findsOneWidget);
      expect(find.text(sampleQuest2.hint!), findsOneWidget);
      expect(find.byType(TypeToConfirmOverlay), findsNothing);
    });

    testWidgets('27. handles minimal quest without optional hint or explanation cleanly', (tester) async {
      final minimalLoadedState = VocabularyLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpScreen(tester, state: minimalLoadedState);

      expect(find.text('ACT'), findsOneWidget);
      expect(find.text('-TION'), findsOneWidget);
      expect(find.text('-MENT'), findsOneWidget);
    });
  });

  group('Group 6: Responsive Layout & Theme Adaptability', () {
    testWidgets('28. renders cleanly without overflow on compact phone (320x568)', (tester) async {
      await pumpScreen(tester, size: const Size(320, 568));

      expect(find.text('CREATE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('29. renders cleanly on tablet (768x1024)', (tester) async {
      await pumpScreen(tester, size: const Size(768, 1024));

      expect(find.text('CREATE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('30. renders cleanly in landscape mode (800x480)', (tester) async {
      await pumpScreen(tester, size: const Size(800, 480));

      expect(find.text('CREATE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('31. renders cleanly under high text scale (1.5x)', (tester) async {
      await pumpScreen(tester, textScale: 1.5);

      expect(find.text('CREATE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('32. renders cleanly in light theme', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(find.text('CREATE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('33. MorphInjectionRail exposes accessible Semantics labels', (tester) async {
      await pumpScreen(tester);

      final railSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.startsWith('Suffix -tion') ?? false),
      );
      expect(railSemantics, findsOneWidget);
    });
  });
}

