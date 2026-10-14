import 'dart:convert';
import 'dart:io';
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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_numbers_layout.dart';

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

  const testShortQuest = KidsQuest(
    id: 'KIDS_NUMBERS_L2_Q2',
    gameType: 'numbers',
    level: 2,
    instruction: 'How many stars are shining?',
    question: '⭐⭐⭐⭐',
    correctAnswer: '4',
    options: ['5', '3', '4'],
    hint: 'Touch each star once as you count.',
    explanation: 'Touching each star once gives 1, 2, 3, 4.',
    funFact: 'Counting on fingers is one of the oldest ways to count.',
  );

  const testStoryQuest = KidsQuest(
    id: 'KIDS_NUMBERS_L192_Q3',
    gameType: 'numbers',
    level: 192,
    instruction: 'Fair price comparison.',
    question:
        'Shop A sells 4 apples for 8 coins. Shop B sells 5 apples for 10 coins. Which shop gives the better price per apple?',
    correctAnswer: 'They cost the same per apple',
    options: [
      'They cost the same per apple',
      'Shop B is cheaper per apple',
      'Shop A is cheaper per apple',
    ],
    hint: 'Divide the coins by the number of apples for each shop.',
    explanation: 'Both shops charge 2 coins per apple, so they cost the same.',
    funFact: 'Unit price helps you compare deals of different sizes.',
  );

  const testShortLoadedState = KidsLoaded(
    quests: [testShortQuest],
    originalTotalQuests: 1,
    gameType: 'numbers',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testStoryLoadedState = KidsLoaded(
    quests: [testStoryQuest],
    originalTotalQuests: 1,
    gameType: 'numbers',
    level: 192,
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

    when(() => mockKidsBloc.state).thenReturn(testShortLoadedState);
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
      final key = inv.positionalArguments.first as String;
      final fallback = inv.namedArguments[#fallback] as String?;
      if (key == 'games.kids_numbers_drag') {
        return 'Tap a planet or drag it to the rocket! 🚀';
      }
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
          home: KidsNumbersLayout(
            level: level,
            title: 'Numbers',
            primaryColor: const Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }

  group('KidsNumbersLayout Production Tests', () {
    testWidgets('renders instruction badge, rocket target, and spherical planetary options', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify instruction badge is displayed
      expect(find.text('How many stars are shining?'), findsOneWidget);

      // Verify rocket window contains stars question
      expect(find.text('⭐⭐⭐⭐'), findsOneWidget);

      // Verify planetary options are displayed
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Verify action hint subtitle and listen audio badge
      expect(
        find.text('Tap a planet or drag it to the rocket!'),
        findsOneWidget,
      );
      expect(find.text('Listen'), findsOneWidget);
    });

    testWidgets('tap-to-answer submits correct answer to KidsBloc and triggers success haptic', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final correctOption = find.text('4');
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pump();

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockTTSService.speak('4', force: any(named: 'force'))).called(1);
    });

    testWidgets('tap-to-answer submits incorrect answer to KidsBloc and triggers error haptic', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final wrongOption = find.text('5');
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockTTSService.speak('5', force: any(named: 'force'))).called(1);
    });

    testWidgets('audio replay button speaks instruction and question', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find speaker icon on instruction badge
      final audioButtons = find.byIcon(Icons.volume_up_rounded);
      expect(audioButtons, findsWidgets);

      await tester.tap(audioButtons.first);
      await tester.pump();

      verify(() => mockTTSService.speak(
            any(that: contains('How many stars are shining?')),
            force: any(named: 'force'),
          )).called(1);
    });

    testWidgets('drag-and-drop accepts planet dropped onto rocket target and submits answer', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final optionToDrag = find.text('4');
      final rocketTarget = find.byType(DragTarget<String>);

      expect(optionToDrag, findsOneWidget);
      expect(rocketTarget, findsOneWidget);

      final dragLocation = tester.getCenter(optionToDrag);
      final targetLocation = tester.getCenter(rocketTarget);

      final TestGesture gesture = await tester.startGesture(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(targetLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('adapts to mission console and capsule pods for long story problems', (tester) async {
      await tester.pumpWidget(buildTestScreen(
        stateOverride: testStoryLoadedState,
        level: 192,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Console title
      expect(find.text('Question'), findsOneWidget);

      // Verify long question text is rendered
      expect(
        find.textContaining('Shop A sells 4 apples'),
        findsOneWidget,
      );

      // Verify long phrase options are rendered in capsule pods with letters
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('They cost the same per apple'), findsOneWidget);
      expect(find.text('Shop B is cheaper per apple'), findsOneWidget);
      expect(find.text('Shop A is cheaper per apple'), findsOneWidget);

      // Tap on correct capsule pod
      await tester.tap(find.text('They cost the same per apple'));
      await tester.pump();

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('adapts sentence questions with 3+ English words into question console', (tester) async {
      const sentenceQuest = KidsQuest(
        id: 'KIDS_NUMBERS_L1_Q3',
        gameType: 'numbers',
        level: 1,
        instruction: 'Pick the group that shows 2.',
        question: 'Which group has exactly 2 fish?',
        correctAnswer: '🐟🐟',
        options: ['🐟🐟', '🐟', '🐟🐟🐟'],
        hint: 'Count each group.',
        explanation: '🐟🐟 has 2 fish.',
        funFact: 'A pair means two.',
      );

      const sentenceState = KidsLoaded(
        quests: [sentenceQuest],
        originalTotalQuests: 1,
        gameType: 'numbers',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await tester.pumpWidget(buildTestScreen(
        stateOverride: sentenceState,
        level: 1,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Console title "Question" should appear for sentence questions
      expect(find.text('Question'), findsOneWidget);
      expect(find.text('Which group has exactly 2 fish?'), findsOneWidget);
      expect(find.text('🐟🐟'), findsOneWidget);
    });

    testWidgets('rejects further submissions when question is already answered', (tester) async {
      const answeredState = KidsLoaded(
        quests: [testShortQuest],
        originalTotalQuests: 1,
        gameType: 'numbers',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: answeredState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tapping an option should not trigger SubmitKidsAnswer
      await tester.tap(find.text('4'), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
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

      // Check no layout overflows occurred
      expect(tester.takeException(), isNull);
      expect(find.text('How many stars are shining?'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('StoryService resolves warm, human-crafted narrative beats for Level 1 and Level 100 milestone', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final BuildContext context = tester.element(find.byType(KidsNumbersLayout));

      final storyService = StoryService();

      // Level 1: Initial welcome to the space journey
      final beat1 = storyService.getStoryBeat(context, 'numbers', 1);
      expect(beat1, isNotNull);
      expect(beat1!.title, equals('NEW QUEST'));
      expect(beat1.text, contains('Welcome aboard our little rocket!'));
      expect(beat1.mascotEmoji, equals('🔢'));

      // Level 100: Major milestone celebration
      final beat100 = storyService.getStoryBeat(context, 'numbers', 100);
      expect(beat100, isNotNull);
      expect(beat100!.title, equals('ADVENTURE LOG'));
      expect(beat100.text, contains('One hundred missions finished!'));
      expect(beat100.mascotEmoji, equals('🔢'));
    });

    testWidgets('GameInstructionService resolves Numbers briefing matching rocket window, dual tap/drag, and friendly tip without buzzwords', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final BuildContext context = tester.element(find.byType(KidsNumbersLayout));

      final briefing = GameInstructionService.getBriefing(context, null, 'numbers', level: 1);

      expect(briefing.title, equals('Numbers in Space'));
      expect(briefing.objective, contains('rocket window'));
      expect(briefing.objective, contains('spaceship fly'));
      expect(briefing.rules.any((r) => r.contains('rocket window')), isTrue);
      expect(briefing.rules.any((r) => r.contains('Tap a planet or drag it')), isTrue);
      expect(briefing.rules.any((r) => r.contains('speaker button')), isTrue);
      expect(briefing.actionText, equals("Let's Count!"));
      expect(briefing.tip, contains('tap each item on the screen with your finger while counting out loud'));
      expect(briefing.tip.contains('PRO TIP'), isFalse);
      expect(briefing.objective.contains('Houston'), isFalse);
    });

    test('assets/translations/en.json contains human, non-robotic copy for instructions and story scripts without gamer buzzwords', () {
      final file = File('assets/translations/en.json');
      expect(file.existsSync(), isTrue);

      final Map<String, dynamic> jsonMap = json.decode(file.readAsStringSync());
      final instructions = jsonMap['instructions'] as Map<String, dynamic>;
      final numbersInstructions = instructions['numbers'] as Map<String, dynamic>;

      expect(numbersInstructions['title'], equals('Numbers in Space'));
      expect(numbersInstructions['objective'], contains('rocket window'));
      expect(numbersInstructions['objective'], isNot(contains('Houston')));
      expect(numbersInstructions['rule_0'], contains('pictures or numbers in the rocket window'));
      expect(numbersInstructions['rule_1'], contains('Tap a planet or drag it'));
      expect(numbersInstructions['rule_2'], contains('speaker button'));
      expect(numbersInstructions['actionText'], equals("Let's Count!"));
      expect(numbersInstructions['tip'], contains('Helpful tip:'));
      expect(numbersInstructions['tip'], isNot(contains('PRO TIP')));

      final storyScripts = jsonMap['story_scripts'] as Map<String, dynamic>;
      expect(storyScripts['numbers'], contains('Welcome aboard our little rocket!'));
      expect(storyScripts['numbers_beat_0'], contains('Welcome aboard our little rocket!'));
      expect(storyScripts['numbers_beat_1'], contains('flying high'));
      expect(storyScripts['numbers_beat_2'], contains('Twenty missions complete'));
      expect(storyScripts['numbers_beat_3'], contains('Halfway to 100'));
      expect(storyScripts['numbers_beat_4'], contains('One hundred missions finished!'));
      expect(storyScripts['numbers_beat_5'], contains('Two hundred space journeys complete!'));

      // Validate NO fantasy dragons or wizards or buzzwords in numbers space game
      expect(storyScripts['numbers_beat_1'], isNot(contains('dragon')));
      expect(storyScripts['numbers_beat_3'], isNot(contains('wizard')));
    });
  });
}

