import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_verbs_layout.dart';

class MockKidsBloc extends MockBloc<KidsEvent, KidsState> implements KidsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockKidsTTSService extends Mock implements KidsTTSService {}

class MockKidsAudioService extends Mock implements KidsAudioService {}

class MockHapticService extends Mock implements HapticService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const SubmitKidsAnswer(true));
  });

  late MockKidsBloc mockKidsBloc;
  late MockAuthBloc mockAuthBloc;
  late MockKidsTTSService mockTTSService;
  late MockKidsAudioService mockAudioService;
  late MockHapticService mockHapticService;
  late MockAppLogger mockLogger;
  late MockLocaleService mockLocaleService;

  const testQuestL1 = KidsQuest(
    id: 'KIDS_VERBS_L2_Q1',
    gameType: 'verbs',
    level: 2,
    instruction:
        'Mia bites into a crunchy apple at lunchtime. Which verb fits the scene?',
    question: '?',
    correctAnswer: 'Eat 🍎',
    options: ['Drink 🥤', 'Eat 🍎', 'Cook 🍳'],
    hint: 'Picture what your mouth and teeth are busy with at lunchtime.',
    emoji: '🍎',
    explanation:
        'Eat means to take food into your mouth, chew it and swallow it. Drink is the word for liquids.',
    funFact: 'Your front teeth cut food and your back teeth grind it.',
  );

  const testQuestPastTense = KidsQuest(
    id: 'KIDS_VERBS_L191_Q1',
    gameType: 'verbs',
    level: 191,
    instruction:
        '\'Did you find your keys?\' \'Yes, I ___ them under the cushion.\'',
    question: '?',
    correctAnswer: 'Found 🔍',
    options: ['Finds 🔍', 'Found 🔍', 'Founded 🔍'],
    hint: 'The search was finished a moment ago.',
    emoji: '🔍',
    explanation:
        'Find becomes \'found\' in the past. \'Founded\' is a different word.',
    funFact: '\'Found\' is the past of \'find\'.',
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuestL1],
    originalTotalQuests: 1,
    gameType: 'verbs',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockKidsBloc = MockKidsBloc();
    mockAuthBloc = MockAuthBloc();
    mockTTSService = MockKidsTTSService();
    mockAudioService = MockKidsAudioService();
    mockHapticService = MockHapticService();
    mockLogger = MockAppLogger();
    mockLocaleService = MockLocaleService();

    when(() => mockKidsBloc.state).thenReturn(testLoadedState);
    when(() => mockKidsBloc.stream)
        .thenAnswer((_) => const Stream<KidsState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'kid_user_1',
          email: 'kid@vowl.app',
          completedLevels: {},
          totalExp: 50,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockTTSService.speak(any(), force: any(named: 'force')))
        .thenAnswer((_) async => true);
    when(() => mockTTSService.stop()).thenAnswer((_) => Future.value());
    when(() => mockTTSService.isNarrationEnabled())
        .thenAnswer((_) async => false);

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    when(() => mockAudioService.playLevelCompleteSFX())
        .thenAnswer((_) async {});

    when(() => mockLocaleService.tr(any()))
        .thenAnswer((inv) => inv.positionalArguments.first as String);

    if (di.sl.isRegistered<KidsTTSService>()) di.sl.unregister<KidsTTSService>();
    if (di.sl.isRegistered<KidsAudioService>()) {
      di.sl.unregister<KidsAudioService>();
    }
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();

    di.sl.registerSingleton<KidsTTSService>(mockTTSService);
    di.sl.registerSingleton<KidsAudioService>(mockAudioService);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  Future<void> pumpVerbsLayout(
    WidgetTester tester, {
    KidsState? state,
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
      when(() => mockKidsBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<KidsBloc>.value(value: mockKidsBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, height),
                  textScaler: TextScaler.noScaling,
                ),
                child: const KidsVerbsLayout(
                  level: 2,
                  title: 'Verbs',
                  primaryColor: Color(0xFF6366F1),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('KidsVerbsLayout Production Audit Tests', () {
    testWidgets('renders stadium jumbotron, scoreboard header, scenario clue, and 3 sports balls',
        (tester) async {
      await pumpVerbsLayout(tester);

      expect(find.text('Action Story'), findsOneWidget);
      expect(
        find.text(
          'Mia bites into a crunchy apple at lunchtime. Which verb fits the scene?',
        ),
        findsWidgets,
      );
      expect(find.text('Eat'), findsOneWidget);
      expect(find.text('Drink'), findsOneWidget);
      expect(find.text('Cook'), findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);
      expect(find.byType(DragTarget<String>), findsOneWidget);
    });

    testWidgets('supports accessible tap-to-answer submission (dual interaction)',
        (tester) async {
      await pumpVerbsLayout(tester);

      // Tap the correct sports ball 'Eat'
      await tester.tap(find.text('Eat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Eat', force: true)).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(
        () => mockLogger.debug(any(), tag: any(named: 'tag')),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('supports drag-and-drop of sports ball to stadium jumbotron scoreboard',
        (tester) async {
      await pumpVerbsLayout(tester);

      final eatFinder = find.text('Eat');
      final scoreboardFinder = find.byType(DragTarget<String>);

      expect(eatFinder, findsOneWidget);
      expect(scoreboardFinder, findsOneWidget);

      final dragLocation = tester.getCenter(scoreboardFinder);
      final gesture = await tester.startGesture(tester.getCenter(eatFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockTTSService.speak('Eat', force: true)).called(1);
    });

    testWidgets('independent ball speaker button pronounces verb without submitting answer',
        (tester) async {
      await pumpVerbsLayout(tester);

      final speakerButtons = find.byIcon(Icons.volume_up_rounded);
      // First is the jumbotron Listen button, subsequent are ball speakers
      expect(speakerButtons, findsNWidgets(4));

      // Tap speaker on the second ball (Drink)
      await tester.tap(speakerButtons.at(1));
      await tester.pump();

      verify(() => mockTTSService.speak('Drink', force: true)).called(1);
      verify(() => mockHapticService.selection()).called(1);
      // Crucial: Answer submission must NOT have been called on speaker tap
      verifyNever(
        () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
      );
    });

    testWidgets('jumbotron LISTEN button replays full scenario clue audio',
        (tester) async {
      await pumpVerbsLayout(tester);

      final listenFinder = find.text('Listen');
      expect(listenFinder, findsOneWidget);

      await tester.tap(listenFinder);
      await tester.pump();

      verify(() => mockTTSService.speak(
            'Mia bites into a crunchy apple at lunchtime. Which verb fits the scene?',
            force: true,
          )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('celebrates goal on correct answer with GOAL! SCORE! banner and target verb',
        (tester) async {
      const solvedState = KidsLoaded(
        quests: [testQuestL1],
        originalTotalQuests: 1,
        gameType: 'verbs',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpVerbsLayout(tester, state: solvedState);

      expect(find.text('Goal!'), findsOneWidget);
      expect(find.text('EAT'), findsOneWidget);
      expect(find.text('🍎'), findsWidgets);
    });

    testWidgets('handles incorrect answer submission with error haptics and feedback',
        (tester) async {
      await pumpVerbsLayout(tester);

      // Tap wrong option 'Drink'
      await tester.tap(find.text('Drink'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Drink', force: true)).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
    });

    testWidgets('dims distractor option when lifeline hintUsed is active',
        (tester) async {
      const hintActiveState = KidsLoaded(
        quests: [testQuestL1],
        originalTotalQuests: 1,
        gameType: 'verbs',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await pumpVerbsLayout(tester, state: hintActiveState);

      // First distractor 'Drink 🥤' at index 0 should be rendered with dimmed Opacity (0.35)
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      final dimmedFound = opacities.any((o) => (o.opacity - 0.35).abs() < 0.05);
      expect(dimmedFound, isTrue);
    });

    testWidgets('renders past tense verbs safely without overflow on narrow 320dp screen',
        (tester) async {
      const pastTenseState = KidsLoaded(
        quests: [testQuestPastTense],
        originalTotalQuests: 1,
        gameType: 'verbs',
        level: 191,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpVerbsLayout(
        tester,
        state: pastTenseState,
        width: 320,
        height: 560, // short and narrow phone
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Found'), findsOneWidget);
      expect(find.text('Founded'), findsOneWidget);
    });
  });
}
