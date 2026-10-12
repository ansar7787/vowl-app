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
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_routine_layout.dart';

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

  const testQuest = KidsQuest(
    id: 'KIDS_ROUTINE_L2_Q1',
    gameType: 'routine',
    level: 2,
    instruction:
        'Which routine task is done during: "Morning to wake up fresh and feel nice and clean"?',
    question: '?',
    correctAnswer: 'Wash Face 🧼',
    options: [
      'Make Bed 🛏️',
      'Wash Face 🧼',
      'Say Good Night 🌙',
    ],
    hint: 'Cool water and a little soap help with this one.',
    emoji: '🧼',
    explanation: 'Yes! We wash our face in the morning to feel fresh and clean.',
    funFact: 'Washing your face removes invisible sweat and dirt.',
  );

  const testNightQuest = KidsQuest(
    id: 'KIDS_ROUTINE_L2_Q2',
    gameType: 'routine',
    level: 2,
    instruction:
        'Which routine task is done during: "Night to sleep cozy and dream beautiful dreams"?',
    question: '?',
    correctAnswer: 'Go to Bed 🛏️',
    options: [
      'Go to Bed 🛏️',
      'Brush Teeth 🪥',
      'Wake Up ⏰',
    ],
    hint: 'You climb under soft blankets for this one.',
    emoji: '🛏️',
    explanation: 'Yes! We go to bed at night to rest our busy bodies.',
    funFact: 'Sleep helps your brain recharge.',
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuest],
    originalTotalQuests: 1,
    gameType: 'routine',
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
    when(() => mockKidsBloc.stream).thenAnswer(
      (_) => const Stream<KidsState>.empty(),
    );

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
    when(() => mockAuthBloc.stream).thenAnswer(
      (_) => const Stream<AuthState>.empty(),
    );

    when(() => mockTTSService.speak(any(), force: any(named: 'force')))
        .thenAnswer((_) async => true);
    when(() => mockTTSService.isNarrationEnabled()).thenAnswer((_) async => false);
    when(() => mockTTSService.stop()).thenAnswer((_) async {});

    when(() => mockAudioService.playLevelCompleteSFX()).thenAnswer((_) async {});

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.error(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'), tag: any(named: 'tag'))).thenReturn(null);

    when(() => mockLocaleService.tr(any())).thenAnswer((inv) => inv.positionalArguments[0] as String);

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
    if (di.sl.isRegistered<KidsTTSService>()) di.sl.unregister<KidsTTSService>();
    if (di.sl.isRegistered<KidsAudioService>()) di.sl.unregister<KidsAudioService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
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
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<KidsBloc>.value(value: mockKidsBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const KidsRoutineLayout(
            level: 2,
            title: 'Routine',
            primaryColor: Color(0xFFF97316),
          ),
        ),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('KidsRoutineLayout Production Tests', () {
    testWidgets(
      'renders bedroom window, time badge, clue banner, and all options fully with no truncation',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);

        // 1. Time Badge
        expect(find.text('Morning'), findsOneWidget);
        expect(find.text('🌅'), findsOneWidget);

        // 2. Clue Text
        expect(
          find.text('Wake up fresh and feel nice and clean'),
          findsOneWidget,
        );

        // 3. Instruction prompt
        expect(
          find.text('Tap a routine or drag it to the window'),
          findsOneWidget,
        );

        // 4. All options visible
        expect(find.text('Make Bed'), findsOneWidget);
        expect(find.text('Wash Face'), findsOneWidget);
        expect(find.text('Say Good Night'), findsOneWidget);

        // 5. Bedroom window drop target exists
        expect(find.byType(DragTarget<String>), findsOneWidget);
      },
    );

    testWidgets('tap-to-answer submits correct answer to KidsBloc', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      // Find the correct pillow Draggable by data
      final washFaceDraggable = find.byWidgetPredicate(
        (widget) => widget is Draggable<String> && widget.data == 'Wash Face 🧼',
      );
      expect(washFaceDraggable, findsOneWidget);

      await tester.tap(washFaceDraggable);
      await pumpScreen(tester);

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets(
      'tap-to-answer submits incorrect answer and speaks pronunciation',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);

        // Find the wrong pillow Draggable by data
        final makeBedDraggable = find.byWidgetPredicate(
          (widget) => widget is Draggable<String> && widget.data == 'Make Bed 🛏️',
        );
        expect(makeBedDraggable, findsOneWidget);

        await tester.tap(makeBedDraggable);
        await pumpScreen(tester);

        verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
        verify(() => mockHapticService.error()).called(1);
        verify(() => mockTTSService.speak('Make Bed')).called(1);
      },
    );

    testWidgets(
      'option audio speaker button plays option pronunciation via TTS without submitting answer',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);

        // Find speaker icon buttons on the pillows
        final speakerIcons = find.byIcon(Icons.volume_up_rounded);
        // There should be multiple: 1 in header clue banner, 3 on the pillows
        expect(speakerIcons, findsAtLeastNWidgets(4));

        // Tap the third pillow speaker (Say Good Night)
        await tester.tap(speakerIcons.last);
        await pumpScreen(tester);

        verify(
          () => mockTTSService.speak('Say Good Night', force: true),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
        // Did NOT submit answer
        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );

    testWidgets(
      'tapping clue banner or bedroom window replays question instruction via TTS',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);

        // Tap the bedroom window target
        final windowFinder = find.byType(DragTarget<String>);
        expect(windowFinder, findsOneWidget);

        await tester.tap(windowFinder);
        await pumpScreen(tester);

        verify(
          () => mockTTSService.speak(testQuest.instruction, force: true),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
      },
    );

    testWidgets(
      'drag-and-drop correct option onto bedroom window target submits answer',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);

        final correctDraggable = find.byWidgetPredicate(
          (widget) =>
              widget is Draggable<String> && widget.data == 'Wash Face 🧼',
        );
        expect(correctDraggable, findsOneWidget);

        final dropTarget = find.byType(DragTarget<String>);
        expect(dropTarget, findsOneWidget);

        // Drag option into bedroom window
        await tester.drag(correctDraggable, const Offset(0, -280));
        await pumpScreen(tester);

        verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      },
    );

    testWidgets('unanswered state does not spoil answer emoji silhouette', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      // In the window target, there should be "Match the routine", NOT the answer emoji
      expect(find.text('Match the routine'), findsOneWidget);
    });

    testWidgets(
      'correct state reveals triumphant celebration with answer emoji inside the window',
      (tester) async {
        final correctState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await tester.pumpWidget(
          buildTestScreen(stateOverride: correctState),
        );
        await pumpScreen(tester);

        // Reveal answer emoji and title in window
        expect(find.text('Wash Face'), findsAtLeastNWidgets(1));
        expect(find.text('🧼'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('accurately adapts for Night routine clue', (tester) async {
      final nightState = const KidsLoaded(
        quests: [testNightQuest],
        originalTotalQuests: 1,
        gameType: 'routine',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await tester.pumpWidget(
        buildTestScreen(stateOverride: nightState),
      );
      await pumpScreen(tester);

      expect(find.text('Bedtime'), findsOneWidget);
      expect(find.text('🌙'), findsAtLeastNWidgets(1));
      expect(
        find.text('Sleep cozy and dream beautiful dreams'),
        findsOneWidget,
      );
    });

    testWidgets('renders cleanly on compact 360x640 phone without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Wash Face'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders cleanly on large 430x932 phone without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Wash Face'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders cleanly on ultra-narrow 320x568 phone without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Wash Face'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
      'already answered state disables re-submitting upon taps',
      (tester) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await tester.pumpWidget(
          buildTestScreen(stateOverride: answeredState),
        );
        await pumpScreen(tester);

        // In answered state, options are not wrapped in Draggable or ScaleButton
        final draggableFinder = find.byType(Draggable<String>);
        expect(draggableFinder, findsNothing);

        // Verification that no SubmitKidsAnswer event was dispatched
        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );

    test('RoutineOptionData.parse extracts emoji and cleans title with zero emoji leakage', () {
      final sample1 = RoutineOptionData.parse('Make Bed 🛏️');
      expect(sample1.title, equals('Make Bed'));
      expect(sample1.emoji, equals('🛏️'));
      expect(sample1.raw, equals('Make Bed 🛏️'));

      final sample2 = RoutineOptionData.parse('Set an Alarm ⏰');
      expect(sample2.title, equals('Set an Alarm'));
      expect(sample2.emoji, equals('⏰'));

      final sample3 = RoutineOptionData.parse('Check the Weather ⛅');
      expect(sample3.title, equals('Check the Weather'));
      expect(sample3.emoji, equals('⛅'));

      final sample4 = RoutineOptionData.parse('Wash Face 🧼');
      expect(sample4.title, equals('Wash Face'));
      expect(sample4.emoji, equals('🧼'));
    });

    testWidgets(
      'option card renders emoji at top and title below on its own separate line',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);

        // Find the text for "Wash Face" (title text alone, without emoji)
        final titleFinder = find.text('Wash Face');
        expect(titleFinder, findsOneWidget);

        // Find the emoji alone in its own Text widget
        final emojiFinder = find.text('🧼');
        expect(emojiFinder, findsOneWidget);

        // There must NOT be any widget combining "Wash Face 🧼" on one line
        expect(find.text('Wash Face 🧼'), findsNothing);

        // Verify vertical stacking: emoji is positioned above the title text
        final emojiCenter = tester.getCenter(emojiFinder);
        final titleCenter = tester.getCenter(titleFinder);
        expect(
          emojiCenter.dy,
          lessThan(titleCenter.dy),
          reason: 'Emoji must be at the top inside the card, above the text',
        );
      },
    );

    testWidgets('interaction triggers structured debug logs via AppLogger', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      final washFaceDraggable = find.byWidgetPredicate(
        (widget) => widget is Draggable<String> && widget.data == 'Wash Face 🧼',
      );
      expect(washFaceDraggable, findsOneWidget);

      await tester.tap(washFaceDraggable);
      await pumpScreen(tester);

      verify(
        () => mockLogger.debug(
          any(that: contains('KidsRoutineLayout: Submitting option "Wash Face 🧼"')),
        ),
      ).called(1);
    });
  });

  group('Routine Game Service Integration Tests', () {
    test('StoryService kidsScripts defines all routine milestone beats up to level 100 and beyond without buzzwords', () {
      final routineBeats = StoryServiceImpl.kidsScripts['routine'];
      expect(routineBeats, isNotNull);
      expect(routineBeats!.length, equals(6));

      // Level 1 / Beat 0
      expect(routineBeats[0], contains('Welcome to Daily Routines!'));
      expect(routineBeats[0], contains('waking up in the morning to cozy bedtime'));

      // Level 10 / Beat 1
      expect(routineBeats[1], contains('first 10 levels'));
      expect(routineBeats[1], contains('morning, afternoon, and evening routines'));

      // Level 20 / Beat 2
      expect(routineBeats[2], contains('Twenty levels complete'));

      // Level 50 / Beat 3
      expect(routineBeats[3], contains('Fifty levels done'));

      // Level 100 / Beat 4 (100 Level milestone)
      expect(routineBeats[4], contains('One hundred levels completed!'));
      expect(routineBeats[4], contains('happy, healthy, and organized'));

      // Level 200 / Beat 5
      expect(routineBeats[5], contains('Two hundred levels completed!'));

      // Verify no robotic buzzwords or grandiose hyperbole
      for (final beat in routineBeats) {
        expect(beat, isNot(contains('destiny')));
        expect(beat, isNot(contains('Super-Saiyan')));
        expect(beat, isNot(contains('Cosmic')));
        expect(beat, isNot(contains('Eternal Hero')));
      }
    });

    testWidgets('GameInstructionService returns authentic Routine briefing matching game mechanics', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final briefing = GameInstructionService.getBriefing(
        capturedContext,
        null,
        'routine',
        level: 1,
      );

      expect(briefing.title, equals('Daily Routines'));
      expect(briefing.icon, equals(Icons.bed_rounded));
      expect(briefing.objective, contains('Match daily routines to the right time of day'));
      expect(briefing.rules.length, equals(3));
      expect(briefing.rules[0], contains('clue at the top'));
      expect(briefing.rules[1], contains('window to see the time of day'));
      expect(briefing.rules[2], contains('matching routine pillow to the window'));
      expect(briefing.actionText, equals("Let's Play"));
      expect(briefing.tip, contains('speaker on any pillow'));
    });
  });
}

