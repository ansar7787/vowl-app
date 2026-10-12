import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_prepositions_layout.dart';

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

  const testQuestGap = KidsQuest(
    id: 'KIDS_PREPOSITIONS_L1_Q1',
    gameType: 'prepositions',
    level: 1,
    instruction:
        'Tom puts his pencils ___ the pencil case. Which word fits best?',
    question: '?',
    correctAnswer: 'In',
    options: ['On', 'In', 'Under'],
    hint: 'A pencil case has walls and a zip.',
    emoji: '✏️',
    explanation: "We use 'in' when something is inside a space.",
    funFact: "We also use 'in' for rooms.",
  );

  const testQuestSentenceChoice = KidsQuest(
    id: 'KIDS_PREPOSITIONS_L1_Q3',
    gameType: 'prepositions',
    level: 1,
    instruction:
        'Sana packed her toy and zipped her school bag. Which sentence tells where the toy is?',
    question: '?',
    correctAnswer: 'The toy is in the bag.',
    options: [
      'The toy is in the bag.',
      'The toy is on the bag.',
      'The toy is under the bag.',
    ],
    hint: 'Zipped means closed up.',
    emoji: '🎒',
    explanation: "The bag is zipped, so the toy is inside it.",
    funFact: "English often uses 'is' plus a place word.",
  );

  const testQuestStartBlank = KidsQuest(
    id: 'KIDS_PREPOSITIONS_L150_Q2',
    gameType: 'prepositions',
    level: 150,
    instruction:
        '___ pizza, we are having salad and fruit for lunch. Which word fits?',
    question: '?',
    correctAnswer: 'Instead of',
    options: ['Instead of', 'Between', 'Behind'],
    hint: 'Think about eating one thing rather than another.',
    emoji: '🍕',
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuestGap],
    originalTotalQuests: 1,
    gameType: 'prepositions',
    level: 1,
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
    when(
      () => mockKidsBloc.stream,
    ).thenAnswer((_) => const Stream<KidsState>.empty());

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
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(
      () => mockTTSService.isNarrationEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => mockTTSService.speak(any(), force: any(named: 'force')),
    ).thenAnswer((_) async => true);
    when(() => mockTTSService.stop()).thenAnswer((_) => Future.value());
    when(() => mockTTSService.dispose()).thenAnswer((_) => Future.value());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(any())).thenAnswer((inv) {
      final key = inv.positionalArguments.first as String;
      if (key == 'games.kids_prepositions_drag') {
        return 'Choose the word that fits.';
      }
      if (key == 'games.kids_prepositions_choose_sentence') {
        return 'Choose the sentence that fits.';
      }
      return key;
    });

    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl.unregister<KidsTTSService>();
    }
    if (di.sl.isRegistered<KidsAudioService>()) {
      di.sl.unregister<KidsAudioService>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }

    di.sl.registerSingleton<KidsTTSService>(mockTTSService);
    di.sl.registerSingleton<KidsAudioService>(mockAudioService);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl.unregister<KidsTTSService>();
    }
    if (di.sl.isRegistered<KidsAudioService>()) {
      di.sl.unregister<KidsAudioService>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget buildTestScreen({
    Size screenSize = const Size(390, 844),
    KidsState? stateOverride,
  }) {
    if (stateOverride != null) {
      when(() => mockKidsBloc.state).thenReturn(stateOverride);
    }

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<KidsBloc>.value(value: mockKidsBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const KidsPrepositionsLayout(
              level: 2,
              title: 'Prepositions',
              primaryColor: Color(0xFF4C1D95),
            ),
          ),
        ),
      ),
    );
  }

  group('PrepositionsQuestHelper Unit Tests', () {
    test('hasBlank accurately detects blank patterns', () {
      expect(PrepositionsQuestHelper.hasBlank(testQuestGap), isTrue);
      expect(
        PrepositionsQuestHelper.hasBlank(testQuestSentenceChoice),
        isFalse,
      );
      expect(PrepositionsQuestHelper.hasBlank(testQuestStartBlank), isTrue);
    });

    test('parseGapQuest parses prefix, suffix, and prompt cleanly', () {
      final info = PrepositionsQuestHelper.parseGapQuest(testQuestGap);
      expect(info.prefix, 'Tom puts his pencils ');
      expect(info.suffix, ' the pencil case.');
      expect(info.prompt, 'Which word fits best?');
      expect(info.fullSentence, 'Tom puts his pencils ___ the pencil case.');
      expect(
        info.completedSentence('In'),
        'Tom puts his pencils In the pencil case.',
      );
    });

    test('parseGapQuest handles blank at sentence beginning', () {
      final info = PrepositionsQuestHelper.parseGapQuest(testQuestStartBlank);
      expect(info.prefix, '');
      expect(info.suffix, ' pizza, we are having salad and fruit for lunch.');
      expect(info.prompt, 'Which word fits?');
      expect(
        info.completedSentence('instead of'),
        'Instead of pizza, we are having salad and fruit for lunch.',
      );
    });

    test('hasLongOptions identifies sentence-length options', () {
      expect(PrepositionsQuestHelper.hasLongOptions(testQuestGap), isFalse);
      expect(
        PrepositionsQuestHelper.hasLongOptions(testQuestSentenceChoice),
        isTrue,
      );
    });
  });

  group('KidsPrepositionsLayout Widget Tests', () {
    testWidgets(
      'renders Magic Stage with emoji, sentence with blank, and 3 Top Hats',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Emoji should be rendered on the magic stage
        expect(find.text('✏️'), findsOneWidget);

        // Blank slot should show '___'
        expect(find.text('___'), findsOneWidget);

        // Top hat option plaques should be visible
        expect(find.text('On'), findsOneWidget);
        expect(find.text('In'), findsOneWidget);
        expect(find.text('Under'), findsOneWidget);
      },
    );

    testWidgets('allows accessible tap-to-answer submission', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the 'In' top hat option
      await tester.tap(find.text('In'));
      await tester.pump();

      // SubmitKidsAnswer(true) should be dispatched to KidsBloc
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);

      // Telemetry log should be recorded
      verify(
        () => mockLogger.debug(
          any(that: contains('Submitted option "In"')),
          tag: 'KidsPrepositions',
        ),
      ).called(1);

      // Completed sentence should be voiced by TTS service
      verify(
        () => mockTTSService.speak(
          'Tom puts his pencils In the pencil case.',
          force: true,
        ),
      ).called(1);
    });

    testWidgets('supports Drag-and-Drop to magic stage target', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final hatFinder = find.text('In');
      final stageFinder = find.byType(DragTarget<String>).first;

      // Perform drag gesture from hat to magic stage
      final gesture = await tester.startGesture(tester.getCenter(hatFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(stageFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();

      // SubmitKidsAnswer(true) dispatched via DragTarget
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('replays question audio when stage speaker icon is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final speakerButtons = find.byIcon(Icons.volume_up_rounded);
      expect(speakerButtons, findsWidgets);

      // Tap stage speaker button
      await tester.tap(speakerButtons.first);
      await tester.pump();

      verify(() => mockTTSService.speak(any(), force: true)).called(1);
      verify(
        () => mockLogger.debug(
          any(that: contains('KidsPrepositionsLayout: Replaying audio')),
          tag: 'KidsPrepositions',
        ),
      ).called(1);
    });

    testWidgets('pronounces option word when speaker icon on hat is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final speakerButtons = find.byIcon(Icons.volume_up_rounded);
      expect(speakerButtons, findsWidgets);

      // Tap first option plaque speaker button
      await tester.tap(speakerButtons.at(1));
      await tester.pump();

      verify(() => mockTTSService.speak(any(), force: true)).called(1);
      verify(
        () => mockLogger.debug(
          any(that: contains('KidsPrepositionsLayout: Pronouncing option')),
          tag: 'KidsPrepositions',
        ),
      ).called(1);
    });

    testWidgets('renders full-sentence scroll cards for Archetype B quests', (
      tester,
    ) async {
      final sentenceState = const KidsLoaded(
        quests: [testQuestSentenceChoice],
        originalTotalQuests: 1,
        gameType: 'prepositions',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: sentenceState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Stage emoji
      expect(find.text('🎒'), findsOneWidget);

      // Option sentences should be rendered in scroll cards with A, B, C badges
      expect(find.text('The toy is in the bag.'), findsOneWidget);
      expect(find.text('The toy is on the bag.'), findsOneWidget);
      expect(find.text('The toy is under the bag.'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      // Tapping sentence card submits answer
      await tester.tap(find.text('The toy is in the bag.'));
      await tester.pump();

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('dims a wrong distractor when lifeline hintUsed is true', (
      tester,
    ) async {
      final hintState = const KidsLoaded(
        quests: [testQuestGap],
        originalTotalQuests: 1,
        gameType: 'prepositions',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: hintState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // One distractor should have opacity 0.25
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.any((o) => o.opacity == 0.25), isTrue);
    });

    testWidgets('locks interaction when question is already answered', (
      tester,
    ) async {
      final answeredState = const KidsLoaded(
        quests: [testQuestGap],
        originalTotalQuests: 1,
        gameType: 'prepositions',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: answeredState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Attempting to tap option does NOT dispatch further submits
      await tester.tap(find.text('On'), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('renders without overflow on narrow 320dp screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestScreen(screenSize: const Size(320, 568)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on large 430dp screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestScreen(screenSize: const Size(430, 932)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('StoryService & GameInstructionService Integration Tests', () {
    test('StoryService prepositions scripts provide warm, pedagogical milestones from Level 1 to 200', () {
      final beats = StoryServiceImpl.kidsScripts['prepositions']!;

      expect(beats.length, 6);

      // Level 1: Foundations of location
      expect(beats[0], contains('In, on, and under!'));
      expect(beats[0], contains('placed in everyday sentences'));
      expect(beats[0], isNot(contains('treasure waterfall')));

      // Level 10: First milestone
      expect(beats[1], contains('first 10 levels'));

      // Level 20: Dual prepositions
      expect(beats[2], contains('Twenty levels complete'));
      expect(beats[2], contains('next to'));

      // Level 50: Halfway milestone
      expect(beats[3], contains('Halfway to 100'));

      // Level 100: Complete sentence relationship mastery
      expect(beats[4], contains('One hundred levels completed'));
      expect(beats[4], isNot(contains('Master of the Map')));

      // Level 200: Global fluency
      expect(beats[5], contains('Two hundred levels completed'));
      expect(beats[5], isNot(contains('Grand Navigator')));
    });

    testWidgets('GameInstructionService prepositions briefing matches game mechanics accurately', (tester) async {
      late BuildContext testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final briefing = GameInstructionService.getBriefing(
        testContext,
        null,
        'prepositions',
        level: 1,
      );

      expect(briefing.title, 'Where Is It?');
      expect(
        briefing.objective,
        contains('choose the correct position word to complete the blank'),
      );
      expect(briefing.rules.length, 3);
      expect(briefing.rules[0], contains('sentence clue'));
      expect(briefing.rules[1], contains('matching preposition'));
      expect(briefing.rules[2], contains('speaker icon'));
      expect(briefing.actionText, 'Start Playing');
      expect(briefing.tip, contains("'in'"));
      expect(briefing.tip, isNot(contains('PRO TIP:')));
    });
  });
}
