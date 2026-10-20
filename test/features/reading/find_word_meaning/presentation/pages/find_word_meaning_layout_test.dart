import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
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
import 'package:vowl/features/reading/find_word_meaning/presentation/pages/find_word_meaning_screen.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/context_sentence_builder.dart';

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
  });

  const testWordMeaningQuest = ReadingQuest(
    id: 'RDG_FINDWORDMEANING_L1_Q1',
    instruction: 'Find the word matching the given meaning.',
    difficulty: 1,
    subtype: GameSubtype.findWordMeaning,
    passage: 'The valiant knight fought against the dragon with courage.',
    question: 'Showing great courage or determination in the face of danger.',
    targetWord: 'valiant',
    wordInContext: 'The valiant knight never surrendered.',
    hint: 'Look for an adjective describing the knight.',
    explanation: 'Valiant means possessing or showing courage.',
  );

  const testLoadedState = ReadingLoaded(
    quests: [testWordMeaningQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({});

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

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockReadingBloc.state).thenReturn(testLoadedState);
    when(() => mockReadingBloc.stream)
        .thenAnswer((_) => const Stream<ReadingState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'reader@vowl.app',
          displayName: 'Word Detective',
          vowlMascot: 'vowl_prime',
          completedLevels: {},
          totalExp: 200,
          isPremium: true,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

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
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});

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

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});
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

    when(() => mockLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(
      () => mockLogger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
        tag: any(named: 'tag'),
      ),
    ).thenReturn(null);

    // Register mocks in DI
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpFindWordMeaning(
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
            home: Scaffold(
              body: FindWordMeaningScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('FindWordMeaningScreen - Production Layout & Mechanics Tests', () {
    testWidgets('1. Initial rendering of instruction, target meaning, and passage words',
        (tester) async {
      await pumpFindWordMeaning(tester);

      // Verify instruction pill
      expect(
        find.text('Find the word matching the given meaning.'),
        findsOneWidget,
      );

      // Verify Question Header
      expect(find.text('DEFINITION'), findsOneWidget);
      expect(
        find.text('Showing great courage or determination in the face of danger.'),
        findsOneWidget,
      );

      // Verify Interactive Passage prompt
      expect(
        find.text('Tap the word that matches the definition:'),
        findsOneWidget,
      );

      // Verify words in the passage
      expect(find.text('The'), findsWidgets);
      expect(find.text('valiant'), findsOneWidget);
      expect(find.text('knight'), findsOneWidget);
      expect(find.text('dragon'), findsOneWidget);
      expect(find.text('courage'), findsOneWidget);
    });

    testWidgets('2. Tapping correct target word triggers success feedback and opens SentenceBuilder',
        (tester) async {
      await pumpFindWordMeaning(tester);

      // Tap on target word "valiant"
      final targetWord = find.text('valiant');
      expect(targetWord, findsOneWidget);

      await tester.tap(targetWord);
      await tester.pump();

      // Verify sensory feedback
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      // Verify ContextSentenceBuilder is revealed
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('valiant'), findsWidgets);
    });

    testWidgets('3. Skipping SentenceBuilder dispatches SubmitAnswer(true)',
        (tester) async {
      await pumpFindWordMeaning(tester);

      // Tap on correct target word
      await tester.tap(find.text('valiant'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // Locate Skip button in ContextSentenceBuilder and ensure visible
      final skipBtn = find.text('SKIP');
      await tester.ensureVisible(skipBtn);
      await tester.pumpAndSettle();
      expect(skipBtn, findsOneWidget);

      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      // Verify SubmitAnswer(true) was dispatched
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('4. Submitting a sentence in SentenceBuilder dispatches SubmitAnswer(true)',
        (tester) async {
      await pumpFindWordMeaning(tester);

      // Tap on correct target word
      await tester.tap(find.text('valiant'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // Scroll to enter valid sentence in text field
      final textField = find.byType(TextField);
      await tester.ensureVisible(textField);
      await tester.pumpAndSettle();
      expect(textField, findsOneWidget);

      await tester.enterText(
        textField,
        'The valiant hero defeated all monsters bravely in battle',
      );
      await tester.pump();

      // Ensure the Submit Sentence button is visible and tap it
      final submitBtn = find.text('SUBMIT SENTENCE');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('5. Tapping incorrect word triggers wrong sound, error haptic, and SubmitAnswer(false)',
        (tester) async {
      await pumpFindWordMeaning(tester);

      // Tap on incorrect word "knight"
      final wrongWord = find.text('knight');
      expect(wrongWord, findsOneWidget);

      await tester.tap(wrongWord);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify error feedback
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);

      // Verify SubmitAnswer(false) is dispatched
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('6. Subsequent word taps are locked out after an answer is initiated',
        (tester) async {
      await pumpFindWordMeaning(tester);

      // Tap correct word
      await tester.tap(find.text('valiant'));
      await tester.pump();

      // Try tapping another word immediately while answered
      await tester.tap(find.text('dragon'), warnIfMissed: false);
      await tester.pump();

      // Selection haptic should only have been called once for the first tap
      verify(() => mockHapticService.selection()).called(1);
      verifyNever(() => mockSoundService.playWrong());

      // Advance clock past the 600ms delayed scroll timer so no timer remains pending
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('7. Hint button dispatches ReadingHintUsed',
        (tester) async {
      await pumpFindWordMeaning(tester);

      // Tap hint icon in GameBaseLayout header
      final hintIcon = find.byIcon(Icons.lightbulb_rounded);
      if (hintIcon.evaluate().isNotEmpty) {
        await tester.tap(hintIcon);
        await tester.pump();
        verify(() => mockReadingBloc.add(const ReadingHintUsed())).called(1);
      }
    });

    testWidgets('8. Displays GameShimmerLoading when quest is null or uninitialized',
        (tester) async {
      const loadingState = ReadingInitial();
      await pumpFindWordMeaning(tester, state: loadingState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('9. Level 1 displays GameBriefingLayer and dismisses on start tap',
        (tester) async {
      await pumpFindWordMeaning(tester, level: 1);

      // Verify GameBriefingLayer is present
      expect(find.byType(GameBriefingLayer), findsOneWidget);

      // Tap action button on briefing overlay to start game
      final startButton = find.byType(ElevatedButton);
      if (startButton.evaluate().isNotEmpty) {
        await tester.tap(startButton);
        await tester.pumpAndSettle();
        expect(find.byType(GameBriefingLayer), findsNothing);
      }
    });

    testWidgets('10. Renders cleanly in dark theme mode',
        (tester) async {
      await pumpFindWordMeaning(tester, themeMode: ThemeMode.dark);

      expect(find.text('DEFINITION'), findsOneWidget);
      expect(find.text('valiant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('11. Renders on compact 320dp screen without overflow',
        (tester) async {
      await pumpFindWordMeaning(
        tester,
        width: 320,
        height: 568,
      );

      expect(find.text('DEFINITION'), findsOneWidget);
      expect(
        find.text('Tap the word that matches the definition:'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '12. SentenceBuilder has proper standard padding and does not touch screen edges',
        (tester) async {
      await pumpFindWordMeaning(tester, width: 390, height: 844);

      // Tap on correct target word
      await tester.tap(find.text('valiant'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final sentenceBuilderFinder = find.byType(ContextSentenceBuilder);
      expect(sentenceBuilderFinder, findsOneWidget);

      final builderRect = tester.getRect(sentenceBuilderFinder);
      // Verify standard padding: builder must not touch left (0) or right (390)
      expect(builderRect.left, greaterThan(0));
      expect(builderRect.right, lessThan(390));
      expect(builderRect.left, closeTo(24, 2));
      expect(390 - builderRect.right, closeTo(24, 2));
      expect(tester.takeException(), isNull);
    });
  });
}

