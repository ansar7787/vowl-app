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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_phonics_layout.dart';

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

  const testLetterQuest = KidsQuest(
    id: 'KIDS_PHONICS_L1_Q1',
    gameType: 'phonics',
    level: 1,
    instruction: 'Stretch the first sound in “moon” like a hum: mmm-oon. Which letter makes that sound?',
    question: '?',
    correctAnswer: 'M',
    options: ['S', 'M', 'P'],
    hint: 'Press your lips together and hum.',
    emoji: '🌙',
    explanation: '“Moon” starts with /m/, written with M.',
    funFact: 'The /m/ sound travels through your nose.',
  );

  const testBlankQuest = KidsQuest(
    id: 'KIDS_PHONICS_L91_Q3',
    gameType: 'phonics',
    level: 91,
    instruction: 'Which letters complete the word? tr__n — it runs on tracks.',
    question: '?',
    correctAnswer: 'ai',
    options: ['ai', 'ee', 'ay'],
    hint: 'Which vowel team fits the middle?',
    emoji: '📝',
    explanation: '“Train” has ai in the middle.',
  );

  const testLongOptionQuest = KidsQuest(
    id: 'KIDS_PHONICS_L191_Q2',
    gameType: 'phonics',
    level: 191,
    instruction: 'Which word is made from the chunks “ex” + “plain”?',
    question: '?',
    correctAnswer: 'explain',
    options: ['explain', 'explode', 'expand'],
    hint: 'Blend the chunks.',
    emoji: '🧩',
    explanation: '“Ex” + “plain” makes “explain”.',
  );

  const testLetterLoadedState = KidsLoaded(
    quests: [testLetterQuest],
    originalTotalQuests: 1,
    gameType: 'phonics',
    level: 1,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testBlankLoadedState = KidsLoaded(
    quests: [testBlankQuest],
    originalTotalQuests: 1,
    gameType: 'phonics',
    level: 91,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLongOptionLoadedState = KidsLoaded(
    quests: [testLongOptionQuest],
    originalTotalQuests: 1,
    gameType: 'phonics',
    level: 191,
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

    when(() => mockKidsBloc.state).thenReturn(testLetterLoadedState);
    when(() => mockKidsBloc.stream).thenAnswer((_) => const Stream<KidsState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'kid_tester_1',
          email: 'kid@vowl.app',
          completedLevels: {},
          totalExp: 100,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockTTSService.isNarrationEnabled()).thenAnswer((_) async => true);
    when(() => mockTTSService.speak(any(), force: any(named: 'force')))
        .thenAnswer((_) async => true);
    when(() => mockTTSService.stop()).thenAnswer((_) => Future.value());
    when(() => mockTTSService.dispose()).thenAnswer((_) => Future.value());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(
          any(),
          fallback: any(named: 'fallback'),
          args: any(named: 'args'),
        )).thenAnswer((inv) {
      final fallback = inv.namedArguments[#fallback] as String?;
      final key = inv.positionalArguments.first as String;
      return fallback ?? key;
    });

    if (di.sl.isRegistered<KidsTTSService>()) di.sl.unregister<KidsTTSService>();
    if (di.sl.isRegistered<KidsAudioService>()) di.sl.unregister<KidsAudioService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();

    di.sl.registerSingleton<KidsTTSService>(mockTTSService);
    di.sl.registerSingleton<KidsAudioService>(mockAudioService);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<KidsTTSService>()) di.sl.unregister<KidsTTSService>();
    if (di.sl.isRegistered<KidsAudioService>()) di.sl.unregister<KidsAudioService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
  });

  Widget buildTestScreen({
    Size screenSize = const Size(390, 844),
    KidsState? stateOverride,
    int level = 2,
  }) {
    if (stateOverride != null) {
      when(() => mockKidsBloc.state).thenReturn(stateOverride);
    }

    return ScreenUtilInit(
      designSize: screenSize,
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<KidsBloc>.value(value: mockKidsBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: KidsPhonicsLayout(
            level: level,
            title: 'Phonics',
            primaryColor: const Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }

  group('KidsPhonicsLayout Production Audit Tests', () {
    testWidgets('renders studio monitor, emoji, and vinyl record options', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify emoji is visible
      expect(find.text('🌙'), findsOneWidget);

      // Verify options are displayed
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('tapping vinyl record option submits answer (dual-mode interaction)', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap option 'M' (correct answer)
      final mFinder = find.text('M');
      expect(mFinder, findsOneWidget);
      await tester.tap(mFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify SubmitKidsAnswer(true) was sent to bloc and logged
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockLogger.debug(
            any(that: contains('Submitted option "M"')),
            tag: 'KidsPhonics',
          )).called(1);
    });

    testWidgets('dragging vinyl record option to studio monitor submits answer', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final optionToDrag = find.text('M');
      final monitorTarget = find.byType(DragTarget<String>);

      expect(optionToDrag, findsOneWidget);
      expect(monitorTarget, findsOneWidget);

      final dragLocation = tester.getCenter(optionToDrag);
      final targetLocation = tester.getCenter(monitorTarget);

      final TestGesture gesture = await tester.startGesture(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(targetLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify SubmitKidsAnswer was sent
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('renders word blank puzzle on studio monitor when present in instruction', (tester) async {
      await tester.pumpWidget(buildTestScreen(stateOverride: testBlankLoadedState, level: 91));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify exact blank clue 'tr__n' is surfaced on the studio monitor
      expect(find.text('tr__n'), findsOneWidget);
      expect(find.text('ai'), findsOneWidget);
      expect(find.text('ee'), findsOneWidget);
      expect(find.text('ay'), findsOneWidget);
    });

    testWidgets('renders long multi-letter options cleanly without micro-downscaling or overflow', (tester) async {
      await tester.pumpWidget(buildTestScreen(stateOverride: testLongOptionLoadedState, level: 191));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('explain'), findsOneWidget);
      expect(find.text('explode'), findsOneWidget);
      expect(find.text('expand'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('studio monitor audio button triggers TTS speak for instruction', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find 'Listen' audio button on the studio monitor
      final listenFinder = find.text('Listen');
      expect(listenFinder, findsOneWidget);

      await tester.tap(listenFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockTTSService.speak(any(), force: any(named: 'force'))).called(greaterThanOrEqualTo(1));
      verify(() => mockLogger.debug(
            any(that: contains('Playing audio instruction')),
            tag: 'KidsPhonics',
          )).called(1);
    });

    testWidgets('disables interaction when answerStatus is answered', (tester) async {
      const answeredState = KidsLoaded(
        quests: [testLetterQuest],
        originalTotalQuests: 1,
        gameType: 'phonics',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: answeredState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap an option
      final sFinder = find.text('S');
      await tester.tap(sFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should NOT submit answer again
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('displays FUN FACT and explanation in feedback card upon correct answer', (tester) async {
      const answeredState = KidsLoaded(
        quests: [testLetterQuest],
        originalTotalQuests: 1,
        gameType: 'phonics',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: answeredState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify FUN FACT box and text are displayed
      expect(find.text('FUN FACT'), findsOneWidget);
      expect(find.text('The /m/ sound travels through your nose.'), findsOneWidget);

      // Verify explanation text is displayed
      expect(find.text('“Moon” starts with /m/, written with M.'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow on compact 320dp small phone screens', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(screenSize: const Size(320, 568)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('🌙'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow on large screen (430x932)', (tester) async {
      tester.view.physicalSize = const Size(430 * 3.0, 932 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(screenSize: const Size(430, 932)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('🌙'), findsOneWidget);
    });

    testWidgets('GameInstructionService provides accurate, human, buzzword-free phonics briefing', (tester) async {
      late GameBriefing briefing;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              briefing = GameInstructionService.getBriefing(
                context,
                null,
                'phonics',
                level: 1,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(briefing.title, 'Sound Match');
      expect(briefing.objective, contains('Listen to the sound clue'));
      expect(briefing.objective, isNot(contains('amplifier')));
      expect(briefing.rules.length, 3);
      expect(briefing.tip, contains('Say the sound out loud'));
      expect(briefing.tip, isNot(contains('PRO TIP')));
      expect(briefing.actionText, "Let's Play");
    });

    testWidgets('50/50 lifeline dissolves first distractor when hintUsed is true and options count > 2', (tester) async {
      final hintUsedState = testLetterLoadedState.copyWith(hintUsed: true);
      when(() => mockKidsBloc.state).thenReturn(hintUsedState);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // In testLetterQuest, options are ['S', 'M', 'P'], correct is 'M'
      // The first distractor 'S' should be eliminated by lifeline
      final animatedOpacities = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity));
      final hasZeroOpacity = animatedOpacities.any((ao) => ao.opacity == 0.0);
      expect(hasZeroOpacity, isTrue);

      // Correct answer 'M' and remaining distractor 'P' remain available
      expect(find.text('M'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('tapping replay audio button triggers speech instruction safely', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final listenButtonFinder = find.text('Listen');
      expect(listenButtonFinder, findsOneWidget);

      await tester.tap(listenButtonFinder);
      await tester.pump();

      verify(() => mockTTSService.speak(any(), force: true)).called(greaterThanOrEqualTo(1));
    });

    test('StoryService phonics scripts provide warm, educational, milestone-accurate story beats', () {
      final beats = StoryServiceImpl.kidsScripts['phonics']!;

      expect(beats.length, 6);
      // Level 1: Initial letter sounds
      expect(beats[0], contains('Welcome to Phonics!'));
      expect(beats[0], isNot(contains('Sound Scientist')));

      // Level 10: Beginning & ending sounds
      expect(beats[1], contains('first 10 levels'));

      // Level 20: CVC words and rhyming families
      expect(beats[2], contains('Twenty levels complete'));

      // Level 50: Consonant blends & word families
      expect(beats[3], contains('Halfway to 100'));

      // Level 100: Long vowels, vowel teams, word blanks
      expect(beats[4], contains('One hundred levels completed'));
      expect(beats[4], isNot(contains('Master of the Sound Garden')));

      // Level 200: Syllables, chunks, full fluency
      expect(beats[5], contains('Two hundred levels completed'));
      expect(beats[5], isNot(contains('Legendary Reader')));
    });
  });
}
