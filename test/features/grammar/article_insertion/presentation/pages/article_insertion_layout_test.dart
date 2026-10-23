import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
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
import 'package:vowl/features/grammar/article_insertion/presentation/pages/article_insertion_screen.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/widgets/article_floating_orb.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/widgets/article_insertion_instruction.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';

class MockGrammarBloc extends MockBloc<GrammarEvent, GrammarState>
    implements GrammarBloc {}

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

class FakeGrammarEvent extends Fake implements GrammarEvent {}

class FakeGrammarState extends Fake implements GrammarState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGrammarBloc mockGrammarBloc;
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
    registerFallbackValue(FakeGrammarEvent());
    registerFallbackValue(FakeGrammarState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const GrammarHintUsed());
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  const testQuest1 = GrammarQuest(
    id: 'GRAM_ART_L1_Q1',
    instruction: 'Select the correct article to complete the sentence.',
    difficulty: 1,
    subtype: GameSubtype.articleInsertion,
    sentence: 'She ate ___ apple in the morning.',
    options: ['a', 'an', 'the', '(no article)'],
    correctAnswer: 'an',
    articleRule: 'Use "an" before words starting with vowel sounds.',
    hint: 'Apple begins with the vowel sound /æ/.',
  );

  const testQuest2 = GrammarQuest(
    id: 'GRAM_ART_L1_Q2',
    instruction: 'Select the correct article to complete the sentence.',
    difficulty: 1,
    subtype: GameSubtype.articleInsertion,
    sentence: 'I saw ___ moon last night.',
    options: ['a', 'an', 'the', 'Ø'],
    correctAnswer: 'the',
    hint: 'There is only one moon.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUp(() async {
    mockGrammarBloc = MockGrammarBloc();
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
      'has_seen_briefing_articleInsertion': true,
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

    when(() => mockGrammarBloc.state).thenReturn(testLoadedState);
    when(
      () => mockGrammarBloc.stream,
    ).thenAnswer((_) => const Stream<GrammarState>.empty());

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

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());

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

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  Future<void> pumpArticleInsertion(
    WidgetTester tester, {
    GrammarState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 844,
  }) async {
    if (state != null) {
      when(() => mockGrammarBloc.state).thenReturn(state);
    }

    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GrammarBloc>.value(value: mockGrammarBloc),
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
            home: ArticleInsertionScreen(
              level: level,
              gameType: GameSubtype.articleInsertion,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ArticleInsertionScreen Layout & Mechanics', () {
    testWidgets('1. renders initial quest with sentence and orbs', (
      tester,
    ) async {
      await pumpArticleInsertion(tester);

      expect(find.byType(ArticleInsertionInstruction), findsOneWidget);
      expect(
        find.textContaining(
          'Select the correct article to complete the sentence',
        ),
        findsOneWidget,
      );
      expect(find.byType(ArticleFloatingOrb), findsNWidgets(4));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('AN'), findsOneWidget);
      expect(find.text('THE'), findsOneWidget);
      expect(find.text('Ø'), findsOneWidget);
      expect(
        find.textContaining('She ate', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('apple in the morning.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('2. displays article rule chip when provided', (tester) async {
      await pumpArticleInsertion(tester);

      expect(
        find.text('Use "an" before words starting with vowel sounds.'),
        findsOneWidget,
      );
    });

    testWidgets('3. renders shimmer loading when state is GrammarLoading', (
      tester,
    ) async {
      await pumpArticleInsertion(tester, state: const GrammarLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ArticleFloatingOrb), findsNothing);
    });

    testWidgets(
      '4. tapping incorrect orb submits wrong answer to GrammarBloc',
      (tester) async {
        await pumpArticleInsertion(tester);

        final orbFinder = find.byKey(const ValueKey('article_orb_0'));
        expect(orbFinder, findsOneWidget);

        await tester.tap(orbFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockHapticService.selection()).called(1);
        verify(
          () => mockGrammarBloc.add(
            any(
              that: isA<SubmitAnswer>().having(
                (e) => e.isCorrect,
                'isCorrect',
                false,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('5. tapping correct orb opens Phase 2 TypeToConfirmOverlay', (
      tester,
    ) async {
      await pumpArticleInsertion(tester);

      final orbFinder = find.byKey(const ValueKey('article_orb_1')); // 'an'
      expect(orbFinder, findsOneWidget);

      await tester.tap(orbFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      expect(
        find.byType(TypeToConfirmOverlay, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(
          'Type the complete sentence to confirm your answer',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      '6. Phase 2: typing correct sentence confirms and submits answer',
      (tester) async {
        await pumpArticleInsertion(tester);

        // Tap orb 1 ('an')
        await tester.tap(find.byKey(const ValueKey('article_orb_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          find.byType(TypeToConfirmOverlay, skipOffstage: false),
          findsOneWidget,
        );

        // Scroll down to bring TypeToConfirmOverlay fully onstage
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        await tester.enterText(
          textFieldFinder,
          'She ate an apple in the morning.',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final submitBtn = find.text('SUBMIT');
        expect(submitBtn, findsOneWidget);

        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump(const Duration(milliseconds: 500));

        verify(
          () => mockGrammarBloc.add(
            any(
              that: isA<SubmitAnswer>().having(
                (e) => e.isCorrect,
                'isCorrect',
                true,
              ),
            ),
          ),
        ).called(1);

        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets('7. Phase 2: skipping confirm dispatches wrong answer', (
      tester,
    ) async {
      await pumpArticleInsertion(tester);

      // Tap orb 1 ('an')
      await tester.tap(find.byKey(const ValueKey('article_orb_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byType(TypeToConfirmOverlay, skipOffstage: false),
        findsOneWidget,
      );

      // Scroll down to bring TypeToConfirmOverlay fully onstage
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'Wrong sentence entered');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final submitBtn = find.text('SUBMIT');

      // Attempt 1 (ScaleButton has 500ms debounce)
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Attempt 2
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Attempt 3
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Now out of attempts, button changes to 'CONTINUE'
      final continueBtn = find.text('CONTINUE').last;
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(
        () => mockGrammarBloc.add(
          any(
            that: isA<SubmitAnswer>().having(
              (e) => e.isCorrect,
              'isCorrect',
              false,
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('8. tapping orbs when already answered does nothing', (
      tester,
    ) async {
      final answeredState = GrammarLoaded(
        quests: const [testQuest1, testQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpArticleInsertion(tester, state: answeredState);

      clearInteractions(mockHapticService);
      clearInteractions(mockGrammarBloc);

      await tester.tap(find.byKey(const ValueKey('article_orb_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockHapticService.selection());
      verifyNever(() => mockGrammarBloc.add(any()));
    });

    testWidgets('9. tapping hint button dispatches GrammarHintUsed', (
      tester,
    ) async {
      await pumpArticleInsertion(tester);

      final hintButtonFinder = find.byType(QuestHintButton);
      expect(hintButtonFinder, findsOneWidget);

      await tester.tap(hintButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
    });

    testWidgets('10. shows level 1 briefing dialog when not yet seen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_articleInsertion': false,
      });

      await pumpArticleInsertion(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final dismissButton = find.text('POP ORB');
      expect(dismissButton, findsOneWidget);

      await tester.ensureVisible(dismissButton);
      await tester.tap(dismissButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('11. supports reduced motion without continuous tickers', (
      tester,
    ) async {
      VowlMotion.lowAnimationModeOverride.value = true;

      await pumpArticleInsertion(tester);

      expect(find.byType(ArticleInsertionScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      // Tickers are stopped under reduced motion
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets(
      '12. handles compact mobile layout (320x568) without overflow',
      (tester) async {
        await pumpArticleInsertion(tester, width: 320, height: 568);

        expect(find.byType(ArticleInsertionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('13. handles tablet viewport (768x1024) without overflow', (
      tester,
    ) async {
      await pumpArticleInsertion(tester, width: 768, height: 1024);

      expect(find.byType(ArticleInsertionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. renders correctly in dark mode', (tester) async {
      await pumpArticleInsertion(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ArticleInsertionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. displays no-article Ø properly when option is Ø', (
      tester,
    ) async {
      final stateQuest2 = GrammarLoaded(
        quests: const [testQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpArticleInsertion(tester, state: stateQuest2);

      expect(find.text('THE'), findsOneWidget);
      expect(find.text('Ø'), findsOneWidget);
      expect(find.textContaining('I saw', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('moon last night.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets(
      '16. renders final failure state with correct answer highlighted',
      (tester) async {
        final failState = GrammarLoaded(
          quests: const [testQuest1],
          currentIndex: 0,
          livesRemaining: 0,
          answerStatus: AnswerStatus.incorrect,
          hintUsed: false,
          wrongCount: 3,
          isFinalFailure: true,
        );

        await pumpArticleInsertion(tester, state: failState);

        expect(find.byType(ArticleFloatingOrb), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
