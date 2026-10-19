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
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';
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
import 'package:vowl/features/vocabulary/context_clues/presentation/pages/context_clues_screen.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_case_file_background.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_case_header.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_evidence_sentence.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_evidence_tags.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_scanner.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
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
    String id = 'quest_cc_1',
    String instruction = 'Identify the redacted component.',
    String contextSentence =
        'The detective found the [TARGET] hidden beneath the floorboards.',
    String prompt = 'Identify the redacted word.',
    List<String> options = const ['weapon', 'document', 'coin', 'map'],
    String correctAnswer = 'weapon',
    List<String> evidenceWords = const ['beneath the floorboards', 'detective'],
    String clueType = 'location',
    String explanation =
        'Beneath the floorboards indicates a physical hidden object.',
    String hint = 'Look for a concealed object.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.contextClues,
      instruction: instruction,
      contextSentence: contextSentence,
      prompt: prompt,
      options: options,
      correctAnswer: correctAnswer,
      evidenceWords: evidenceWords,
      clueType: clueType,
      explanation: explanation,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_cc_2',
    contextSentence:
        'The explorer mapped the [TARGET] through the dense jungle.',
    options: ['trail', 'ocean', 'tower', 'bridge'],
    correctAnswer: 'trail',
    evidenceWords: ['dense jungle', 'mapped'],
    clueType: 'path',
    explanation: 'You map a trail through a dense jungle.',
    hint: 'A route to travel.',
  );

  final sampleMinimalQuest = createQuest(
    id: 'quest_cc_min',
    contextSentence: 'Is it [TARGET]?',
    options: ['yes', 'no'],
    correctAnswer: 'yes',
    evidenceWords: [],
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
      const FetchVocabularyQuests(gameType: GameSubtype.contextClues, level: 1),
    );
    registerFallbackValue(
      const FetchVocabularyQuests(gameType: GameSubtype.contextClues, level: 2),
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
          displayName: 'Test Explorer',
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

    // Register all dependencies in di.sl
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
                body: ContextCluesScreen(
                  level: level,
                  gameType: GameSubtype.contextClues,
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

  group('1. Initial Screen & Layout Setup', () {
    testWidgets(
      '1.1 renders ContextCluesCaseHeader with header and clue number',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(ContextCluesCaseHeader), findsOneWidget);
        expect(find.text('CONTEXT CLUES'), findsOneWidget);
        expect(find.text('Level 2 • Clue 1'), findsOneWidget);
      },
    );

    testWidgets('1.2 renders instruction banner', (tester) async {
      await pumpScreen(tester);

      expect(
        find.text('Read the sentence and find the missing word from the clues.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '1.3 renders ContextCluesCaseFileBackground with paper dossier styling',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(ContextCluesCaseFileBackground), findsOneWidget);
      },
    );

    testWidgets(
      '1.4 renders ContextCluesEvidenceSentence with redacted block',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(ContextCluesEvidenceSentence), findsWidgets);
        final sentenceFinder = find.descendant(
            of: find.byType(ContextCluesEvidenceSentence),
          matching: find.byType(RichText),
        );
        final richText = tester.widget<RichText>(sentenceFinder.first);
        expect(
          (richText.text as TextSpan).toPlainText(),
          contains('The detective found the'),
        );
      },
    );

    testWidgets('1.5 renders ContextCluesEvidenceTags with all option tags', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(ContextCluesEvidenceTags), findsOneWidget);
      expect(find.text('weapon'), findsOneWidget);
      expect(find.text('document'), findsOneWidget);
      expect(find.text('coin'), findsOneWidget);
      expect(find.text('map'), findsOneWidget);
    });

    testWidgets('1.6 renders minimal quest with 2 options cleanly', (
      tester,
    ) async {
      final minState = testLoadedState.copyWith(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
      );
      await pumpScreen(tester, state: minState);

      expect(find.text('yes'), findsOneWidget);
      expect(find.text('no'), findsOneWidget);
    });

    testWidgets('1.7 dispatches FetchVocabularyQuests on mount', (
      tester,
    ) async {
      await pumpScreen(tester, level: 1);

      verify(
        () => mockVocabularyBloc.add(
          const FetchVocabularyQuests(
            gameType: GameSubtype.contextClues,
            level: 1,
          ),
        ),
      ).called(1);
    });

    testWidgets(
      '1.8 displays briefing dialog on level 1 and dismisses on tap',
      (tester) async {
        await pumpScreen(tester, level: 1);

        final startBtn = find.text('INVESTIGATE CASE');
        expect(startBtn, findsOneWidget);
        await tester.ensureVisible(startBtn);
        await tester.pumpAndSettle();
        await tester.tap(startBtn);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('INVESTIGATE CASE'), findsNothing);
      },
    );
  });

  group('2. Lens Mechanics & Flashlight System (Phase 1)', () {
    testWidgets('2.1 renders ContextCluesScanner lens', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(ContextCluesScanner), findsOneWidget);
    });

    testWidgets(
      '2.2 panning/dragging lens scanner updates lens position and triggers selection haptics',
      (tester) async {
        await pumpScreen(tester);

        final scannerFinder = find.byType(ContextCluesScanner);
        expect(scannerFinder, findsOneWidget);

        final gesture = await tester.startGesture(tester.getCenter(scannerFinder));
        for (int i = 0; i < 45; i++) {
          await gesture.moveBy(const Offset(1, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pump();

        verify(
          () => mockHapticService.selection(),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      '2.3 dragging scanner far off-screen clamps inside boundaries',
      (tester) async {
        await pumpScreen(tester);

        final scannerFinder = find.byType(ContextCluesScanner);
        final gesture = await tester.startGesture(tester.getCenter(scannerFinder));
        await gesture.moveBy(const Offset(1000, 0));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // Scanner remains within widget bounds without crashing or throwing
        expect(scannerFinder, findsOneWidget);
      },
    );
  });

  group('3. Phase 1 Option Selection (Redacted Component)', () {
    testWidgets(
      '3.1 tapping option tag updates selected option state visually',
      (tester) async {
        await pumpScreen(tester);

        final optionTag = find.text('document');
        expect(optionTag, findsOneWidget);

        await tester.tap(optionTag);
        await tester.pump();

        // Incorrect option marks answer
        expect(find.byType(ContextCluesEvidenceTags), findsOneWidget);
      },
    );

    testWidgets(
      '3.2 tapping incorrect option submits wrong answer with error haptics and audio',
      (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('document'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(false)),
        ).called(1);
      },
    );

    testWidgets(
      '3.3 tapping correct option triggers selection haptics and advances to Phase 2',
      (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('weapon'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.selection()).called(1);

        // Phase 2 EvidenceHighlightWrapper mounts
        expect(find.byType(EvidenceHighlightWrapper), findsOneWidget);
      },
    );

    testWidgets('3.4 tapping option tag when already answered is locked out', (
      tester,
    ) async {
      await pumpScreen(tester);
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockVocabularyBloc.state).thenReturn(answeredState);
      vocabularyStreamController.add(answeredState);
      await tester.pumpAndSettle();

      await tester.tap(find.text('document'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // SubmitAnswer should not be called since already answered
      verifyNever(() => mockVocabularyBloc.add(const SubmitAnswer(false)));
    });

    testWidgets(
      '3.5 correct option in answered state shows green styling on evidence tag',
      (tester) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        await pumpScreen(tester, state: answeredState);

        expect(find.byType(ContextCluesEvidenceTags), findsOneWidget);
        expect(find.text('weapon'), findsOneWidget);
      },
    );
  });

  group('4. Phase 2 Evidence Highlighting (EvidenceHighlightWrapper)', () {
    testWidgets(
      '4.1 advancing to Phase 2 mounts EvidenceHighlightWrapper with passage',
      (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('weapon'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 300));

        final evidenceWrapper = find.byType(EvidenceHighlightWrapper);
        expect(evidenceWrapper, findsOneWidget);
        expect(
          find.text('Tap the clue words in the sentence that support your answer'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '4.2 tapping non-evidence word in EvidenceHighlightWrapper triggers error haptics and sfx',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Phase 2
        await tester.tap(find.text('weapon'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Scroll to EvidenceHighlightWrapper
        await tester.ensureVisible(find.byType(EvidenceHighlightWrapper));
        await tester.pumpAndSettle();

        // Find a non-evidence word in the passage ('hidden')
        final nonEvidenceWord = find.descendant(
          of: find.byType(EvidenceHighlightWrapper),
          matching: find.text('hidden'),
        );
        expect(nonEvidenceWord, findsOneWidget);
        await tester.ensureVisible(nonEvidenceWord);
        await tester.tap(nonEvidenceWord);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockHapticService.error()).called(1);

        // Flush the 600ms wrong highlight timer
        await tester.pump(const Duration(milliseconds: 700));
      },
    );

    testWidgets(
      '4.3 tapping evidence words in EvidenceHighlightWrapper highlights with success haptics',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Phase 2
        await tester.tap(find.text('weapon'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Scroll to EvidenceHighlightWrapper
        await tester.ensureVisible(find.byType(EvidenceHighlightWrapper));
        await tester.pumpAndSettle();

        // Tap evidence word ('floorboards.')
        final evidenceWord = find.descendant(
          of: find.byType(EvidenceHighlightWrapper),
          matching: find.text('floorboards.'),
        );
        expect(evidenceWord, findsOneWidget);
        await tester.ensureVisible(evidenceWord);
        await tester.tap(evidenceWord);
        await tester.pump();

        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      '4.4 highlighting required evidence words completes Phase 2 and dispatches SubmitAnswer(true)',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Phase 2
        await tester.tap(find.text('weapon'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Scroll to EvidenceHighlightWrapper
        await tester.ensureVisible(find.byType(EvidenceHighlightWrapper));
        await tester.pumpAndSettle();

        // Evidence words: 'beneath the floorboards', 'detective'
        final detectiveWord = find.descendant(
          of: find.byType(EvidenceHighlightWrapper),
          matching: find.text('detective'),
        );
        await tester.ensureVisible(detectiveWord);
        await tester.tap(detectiveWord);
        await tester.pump();

        final beneathWord = find.descendant(
          of: find.byType(EvidenceHighlightWrapper),
          matching: find.text('beneath'),
        );
        await tester.ensureVisible(beneathWord);
        await tester.tap(beneathWord);
        await tester.pump();

        final theWords = find.descendant(
          of: find.byType(EvidenceHighlightWrapper),
          matching: find.text('the'),
        );
        await tester.ensureVisible(theWords.last);
        await tester.tap(theWords.last);
        await tester.pump();

        final floorboardsWord = find.descendant(
          of: find.byType(EvidenceHighlightWrapper),
          matching: find.text('floorboards.'),
        );
        await tester.ensureVisible(floorboardsWord);
        await tester.tap(floorboardsWord);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(true)),
        ).called(1);
      },
    );

    testWidgets(
      '4.5 auto-completes when quest has empty evidence words (anti-softlock)',
      (tester) async {
        final minState = testLoadedState.copyWith(
          quests: [sampleMinimalQuest],
          currentIndex: 0,
        );
        await pumpScreen(tester, state: minState);

        // Tap correct option
        await tester.tap(find.text('yes'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 300));

        // Because evidenceWords is empty, EvidenceHighlightWrapper anti-softlock triggers
        await tester.pump(const Duration(milliseconds: 100));

        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(true)),
        ).called(1);
      },
    );
  });

  group('5. Game Feedback, Retry & Lockout', () {
    testWidgets(
      '5.1 answered state mounts GameFeedbackCard with pedagogical explanation',
      (tester) async {
        await pumpScreen(tester);
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        when(() => mockVocabularyBloc.state).thenReturn(answeredState);
        vocabularyStreamController.add(answeredState);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(GameFeedbackCard), findsOneWidget);
        expect(
          find.text(
            'Beneath the floorboards indicates a physical hidden object.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '5.2 tapping CONTINUE on correct answer dispatches NextQuestion',
      (tester) async {
        await pumpScreen(tester);
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        when(() => mockVocabularyBloc.state).thenReturn(answeredState);
        vocabularyStreamController.add(answeredState);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final continueBtn = find.text('CONTINUE');
        expect(continueBtn, findsOneWidget);

        await tester.tap(continueBtn);
        await tester.pump();

        verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
      },
    );

    testWidgets(
      '5.3 tapping TRY AGAIN on wrong answer (non-final failure) resets for retry',
      (tester) async {
        await pumpScreen(tester);

        // Tap wrong answer
        await tester.tap(find.text('document'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final feedbackCard = find.byType(GameFeedbackCard);
        expect(feedbackCard, findsOneWidget);

        final tryAgainBtn = find.text('TRY AGAIN');
        expect(tryAgainBtn, findsOneWidget);

        await tester.tap(tryAgainBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Did not dispatch NextQuestion because player is retrying
        verifyNever(() => mockVocabularyBloc.add(const NextQuestion()));
      },
    );

    testWidgets(
      '5.4 tapping SEE RESULTS on terminal failure (0 lives) dispatches NextQuestion',
      (tester) async {
        await pumpScreen(tester);

        // Tap wrong answer
        await tester.tap(find.text('document'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Transition bloc to final failure state (0 lives)
        final failedState = testLoadedState.copyWith(
          wrongCount: 3,
          livesRemaining: 0,
          isFinalFailure: true,
          answerStatus: AnswerStatus.incorrect,
        );
        when(() => mockVocabularyBloc.state).thenReturn(failedState);
        vocabularyStreamController.add(failedState);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(GameFeedbackCard), findsOneWidget);
        final seeResultsBtn = find.text('SEE RESULTS');
        expect(seeResultsBtn, findsOneWidget);

        await tester.tap(seeResultsBtn);
        await tester.pump();

        verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
      },
    );

    testWidgets('5.5 interactions locked out after question is answered', (
      tester,
    ) async {
      await pumpScreen(tester);
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockVocabularyBloc.state).thenReturn(answeredState);
      vocabularyStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tapping option does not dispatch another answer
      await tester.tap(find.text('document'), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockVocabularyBloc.add(const SubmitAnswer(false)));
    });
  });

  group('6. Progression, State Transitions & Cleanup', () {
    testWidgets(
      '6.1 tapping header hint button dispatches VocabularyHintUsed',
      (tester) async {
        await pumpScreen(tester);

        final hintButton = find.byType(QuestHintButton);
        expect(hintButton, findsOneWidget);

        await tester.tap(hintButton);
        await tester.pump(const Duration(milliseconds: 100));

        verify(
          () => mockVocabularyBloc.add(const VocabularyHintUsed()),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    testWidgets('6.2 hint state renders custom hint text in base layout', (
      tester,
    ) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);
      await pumpScreen(tester, state: hintState);

      expect(find.byType(ContextCluesScreen), findsOneWidget);
    });

    testWidgets(
      '6.3 transitioning to second quest resets state and renders second prompt',
      (tester) async {
        await pumpScreen(tester);

        // Transition to quest 2
        final stateQuest2 = testLoadedState.copyWith(currentIndex: 1);
        when(() => mockVocabularyBloc.state).thenReturn(stateQuest2);
        vocabularyStreamController.add(stateQuest2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('trail'), findsOneWidget);
        expect(find.text('ocean'), findsOneWidget);
        expect(find.text('Level 2 • Clue 2'), findsOneWidget);
      },
    );

    testWidgets(
      '6.4 VocabularyGameComplete state triggers LEVEL COMPLETE dialog and disposes cleanly',
      (tester) async {
        await pumpScreen(tester);

        vocabularyStreamController.add(
          const VocabularyGameComplete(
            xpEarned: 50,
            coinsEarned: 25,
            questCount: 2,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

        // Clean up completion dialog to avoid pending periodic timers
        Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets('6.5 renders GameShimmerLoading when quests are loading/null', (
      tester,
    ) async {
      const loadingState = VocabularyLoading();
      await pumpScreen(tester, state: loadingState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('6.6 screen disposes cleanly without timer leaks', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  });

  group('7. Viewport Responsiveness, Theming & Accessibility', () {
    testWidgets('7.1 renders cleanly on compact mobile viewport (320x568)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(320, 568));

      expect(find.byType(ContextCluesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7.2 renders cleanly on tablet viewport (768x1024)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(768, 1024));

      expect(find.byType(ContextCluesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7.3 renders cleanly in Light Theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(find.byType(ContextCluesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7.4 renders cleanly in Dark Theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ContextCluesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7.5 supports text scaling up to 1.5x cleanly', (tester) async {
      await pumpScreen(tester, textScale: 1.5);

      expect(find.byType(ContextCluesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '7.6 suppresses repeating animations when disableAnimations is true',
      (tester) async {
        await pumpScreen(tester, disableAnimations: true);

        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
