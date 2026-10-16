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
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_screen.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_mission_control.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_synthesizer.dart';

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
    String id = 'quest_ps_1',
    String word = 'happy',
    String rootWord = 'happy',
    String correctAnswer = 'unhappy',
    List<String> options = const ['un-', 're-', 'dis-', '-ful'],
    String hint = 'Not happy; feeling sad or displeased.',
    String instruction = 'Assemble the correct prefix or suffix to match the meaning.',
    String explanation = 'The prefix "un-" expresses negation, creating "unhappy".',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.prefixSuffix,
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
    id: 'quest_ps_2',
    word: 'care',
    rootWord: 'care',
    correctAnswer: 'careful',
    options: ['un-', '-less', '-ful', 'mis-'],
    hint: 'Taking care or showing caution.',
    instruction: 'Assemble the word using the correct affix.',
    explanation: 'The suffix "-ful" means full of or characterized by.',
  );

  final sampleQuestNoHyphens = createQuest(
    id: 'quest_ps_nohyphen',
    word: 'lock',
    rootWord: 'lock',
    correctAnswer: 'unlock',
    options: ['un', 'dis', 'pre'],
    hint: 'To undo or open a lock.',
    instruction: 'Combine root and affix to match the definition.',
    explanation: 'The prefix "un" reverses the action of locking.',
  );

  final sampleMinimalQuest = const VocabularyQuest(
    id: 'quest_ps_minimal',
    type: QuestType.vocabulary,
    subtype: GameSubtype.prefixSuffix,
    word: 'play',
    rootWord: 'play',
    correctAnswer: 'playful',
    options: ['-ful', '-ish'],
    instruction: 'Assemble the affix.',
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
        gameType: GameSubtype.prefixSuffix,
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
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
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
          id: 'test_user_ps',
          email: 'ps@vowl.app',
          displayName: 'Affix Specialist',
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
                body: PrefixSuffixScreen(
                  level: level,
                  gameType: GameSubtype.prefixSuffix,
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
    await tester.tap(find.text('UN-').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  group('Group 1: Initial Screen Layout & Component Rendering', () {
    testWidgets('1. renders GameShimmerLoading when state has no quest', (tester) async {
      await pumpScreen(tester, state: const VocabularyInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('2. renders PrefixSuffixMissionControl with "TARGET MEANING" and hint', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(PrefixSuffixMissionControl), findsOneWidget);
      expect(find.text('TARGET MEANING'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.text(sampleQuest1.hint!), findsOneWidget);
    });

    testWidgets('3. renders root word block displaying uppercase root word', (tester) async {
      await pumpScreen(tester);

      expect(find.text('HAPPY'), findsOneWidget);
    });

    testWidgets('4. renders drop zones with "PREFIX" and "SUFFIX" labels', (tester) async {
      await pumpScreen(tester);

      expect(find.text('PREFIX'), findsOneWidget);
      expect(find.text('SUFFIX'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsNWidgets(2));
    });

    testWidgets('5. renders all affix option chips in synthesizer arsenal', (tester) async {
      await pumpScreen(tester);

      expect(find.text('UN-'), findsOneWidget);
      expect(find.text('RE-'), findsOneWidget);
      expect(find.text('DIS-'), findsOneWidget);
      expect(find.text('-FUL'), findsOneWidget);
    });

    testWidgets('6. renders header controls including QuestHintButton', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(QuestHintButton), findsOneWidget);
    });
  });

  group('Group 2: Affix Selection & Synthesizer Feedback', () {
    testWidgets('7. tapping correct prefix triggers sound, haptic, and passes stage 1', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('UN-').first);
      await tester.pump();

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });

    testWidgets('8. tapping incorrect affix triggers wrong sound, error haptic, and dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('DIS-').first);
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

    testWidgets('9. dragging correct prefix into prefix slot snaps and advances to stage 2', (tester) async {
      await pumpScreen(tester);

      final dragTargets = tester.widgetList<DragTarget<String>>(find.byType(DragTarget<String>));
      expect(dragTargets.isNotEmpty, isTrue);

      final prefixDropZone = dragTargets.first;
      prefixDropZone.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: 'un-', offset: Offset.zero),
      );
      await tester.pump();

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });

    testWidgets('10. dragging prefix into suffix slot rejects drop without failing game', (tester) async {
      await pumpScreen(tester);

      final dragTargets = tester.widgetList<DragTarget<String>>(find.byType(DragTarget<String>));
      final suffixDropZone = dragTargets.last;

      suffixDropZone.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: 'un-', offset: Offset.zero),
      );
      await tester.pump();

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);

      verifyNever(() => mockVocabularyBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('11. dragging suffix into prefix slot rejects drop without failing game', (tester) async {
      await pumpScreen(tester);

      final dragTargets = tester.widgetList<DragTarget<String>>(find.byType(DragTarget<String>));
      final prefixDropZone = dragTargets.first;

      prefixDropZone.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: '-ful', offset: Offset.zero),
      );
      await tester.pump();

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verifyNever(() => mockVocabularyBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('12. tapping correct suffix on suffix quest advances to stage 2', (tester) async {
      final suffixLoadedState = VocabularyLoaded(
        quests: [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpScreen(tester, state: suffixLoadedState);

      expect(find.text('CARE'), findsOneWidget);

      await tester.tap(find.text('-FUL').first);
      await tester.pump();

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });

    testWidgets('13. correctly infers prefix/suffix when options do not have hyphens', (tester) async {
      final noHyphenLoadedState = VocabularyLoaded(
        quests: [sampleQuestNoHyphens],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpScreen(tester, state: noHyphenLoadedState);

      expect(find.text('LOCK'), findsOneWidget);

      await tester.tap(find.text('UN').first);
      await tester.pump();

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });
  });

  group('Group 3: Stage 2 (Phase 2) Fused Word & TypeToConfirmOverlay', () {
    testWidgets('14. displays fused word block after stage 1 passed', (tester) async {
      await advanceToPhase2(tester);

      expect(find.text('UNHAPPY'), findsWidgets);
    });

    testWidgets('15. displays TypeToConfirmOverlay with expectedText', (tester) async {
      await advanceToPhase2(tester);

      final overlayFinder = find.byType(TypeToConfirmOverlay);
      expect(overlayFinder, findsOneWidget);

      final overlay = tester.widget<TypeToConfirmOverlay>(overlayFinder);
      expect(overlay.expectedText, equals('unhappy'));
    });

    testWidgets('16. confirms stage 2 via onConfirmed triggers sound, TTS, and SubmitAnswer(true)', (tester) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();

      verify(() => mockSoundService.playCorrect()).called(greaterThanOrEqualTo(2));
      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(2));
      verify(() => mockTtsService.speak('unhappy')).called(1);
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isTrue)),
        ),
      ).called(1);
    });

    testWidgets('17. skips stage 2 via onSkipped dispatches SubmitAnswer(false)', (tester) async {
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

    testWidgets('18. bypasses stage 2 via onBypassed dispatches SubmitAnswer(true)', (tester) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onBypassed?.call();
      await tester.pump();

      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isTrue)),
        ),
      ).called(1);
    });

    testWidgets('19. typing correct text in TextField and pressing submit confirms stage 2', (tester) async {
      await advanceToPhase2(tester);

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'unhappy');
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
  });

  group('Group 4: Hint System & Audio Lifecycle', () {
    testWidgets('20. tapping hint button calls TtsService.speak with target word', (tester) async {
      await pumpScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockTtsService.speak('unhappy')).called(1);
      verify(() => mockVocabularyBloc.add(any(that: isA<VocabularyHintUsed>()))).called(1);
    });

    testWidgets('21. tapping hint highlights the correct affix chip', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();

      final synthesizer = tester.widget<PrefixSuffixSynthesizer>(
        find.byType(PrefixSuffixSynthesizer),
      );
      expect(synthesizer.hintedAffix, equals('un-'));
    });

    testWidgets('22. hint highlight auto-clears after timer duration', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();

      var synthesizer = tester.widget<PrefixSuffixSynthesizer>(
        find.byType(PrefixSuffixSynthesizer),
      );
      expect(synthesizer.hintedAffix, equals('un-'));

      await tester.pump(const Duration(milliseconds: 1600));

      synthesizer = tester.widget<PrefixSuffixSynthesizer>(
        find.byType(PrefixSuffixSynthesizer),
      );
      expect(synthesizer.hintedAffix, isNull);
    });

    testWidgets('23. tapping hint during stage 2 speaks target word without crashing', (tester) async {
      await advanceToPhase2(tester);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();

      verify(() => mockTtsService.speak('unhappy')).called(1);
    });
  });

  group('Group 5: State Progression, Error Handling & Navigation', () {
    testWidgets('25. displays success feedback card when answered correctly', (tester) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('26. displays failure feedback card with explanation when answered incorrectly', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('DIS-').first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('27. tapping continue on feedback card dispatches NextQuestion()', (tester) async {
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

    testWidgets('28. transitions from question 0 to question 1 cleanly', (tester) async {
      await pumpScreen(tester);

      expect(find.text('HAPPY'), findsOneWidget);

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

      expect(find.text('CARE'), findsOneWidget);
      expect(find.text(sampleQuest2.hint!), findsOneWidget);
    });

    testWidgets('30. handles minimal quest without optional fields cleanly', (tester) async {
      final minimalLoadedState = VocabularyLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpScreen(tester, state: minimalLoadedState);

      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('-FUL'), findsOneWidget);
      expect(find.text('-ISH'), findsOneWidget);
    });
  });

  group('Group 6: Responsive Layout & Theme Adaptability', () {
    testWidgets('32. renders cleanly without overflow on compact phone (320x568)', (tester) async {
      await pumpScreen(tester, size: const Size(320, 568));

      expect(find.text('HAPPY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('33. renders cleanly on tablet (768x1024)', (tester) async {
      await pumpScreen(tester, size: const Size(768, 1024));

      expect(find.text('HAPPY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('34. renders cleanly in landscape mode (800x480)', (tester) async {
      await pumpScreen(tester, size: const Size(800, 480));

      expect(find.text('HAPPY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('35. renders cleanly under high text scale (1.5x)', (tester) async {
      await pumpScreen(tester, textScale: 1.5);

      expect(find.text('HAPPY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('36. renders cleanly in light theme', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(find.text('HAPPY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
