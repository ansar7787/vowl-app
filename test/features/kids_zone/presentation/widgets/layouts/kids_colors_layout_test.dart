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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_colors_layout.dart';

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

  const testColorQuest = KidsQuest(
    id: 'KIDS_COLORS_L2_Q1',
    gameType: 'colors',
    level: 2,
    instruction: 'A stop sign tells cars to stop. What color is it?',
    question: '?',
    correctAnswer: 'Red',
    options: ['Red', 'Yellow', 'Blue'],
    hint: 'Imagine a fire truck\'s color.',
    emoji: '🚗',
    explanation: 'Stop signs are red so drivers notice them from far away.',
    funFact: 'In many countries, stop signs are red and have eight sides.',
  );

  const testObjectQuest = KidsQuest(
    id: 'KIDS_COLORS_L2_Q2',
    gameType: 'colors',
    level: 2,
    instruction: 'Which one is yellow?',
    question: '?',
    correctAnswer: 'Lemon',
    options: ['Lemon', 'Grass', 'Tomato'],
    hint: 'Picture a rubber duck in the bath.',
    emoji: '🔎',
    explanation: 'A lemon\'s skin is yellow.',
    funFact: 'Lemons grow on trees, and the trees stay green all year.',
  );

  const testFourOptionsQuest = KidsQuest(
    id: 'KIDS_COLORS_L190_Q4',
    gameType: 'colors',
    level: 190,
    instruction:
        'Which rare mineral crystal reflects a luminous deep azure hue with sparkling flecks?',
    question: '?',
    correctAnswer: 'Sapphire',
    options: ['Sapphire', 'Emerald', 'Ruby', 'Topaz'],
    hint: 'Think of a precious blue gemstone.',
    emoji: '💎',
    explanation: 'Sapphires are famed for their celestial blue shades.',
    funFact: 'Sapphire is one of the hardest minerals on Earth.',
  );

  const testLoadedColorState = KidsLoaded(
    quests: [testColorQuest],
    originalTotalQuests: 1,
    gameType: 'colors',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedObjectState = KidsLoaded(
    quests: [testObjectQuest],
    originalTotalQuests: 1,
    gameType: 'colors',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedFourOptionsState = KidsLoaded(
    quests: [testFourOptionsQuest],
    originalTotalQuests: 1,
    gameType: 'colors',
    level: 190,
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

    when(() => mockKidsBloc.state).thenReturn(testLoadedColorState);
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

    when(() => mockLocaleService.tr(any())).thenAnswer(
      (inv) => inv.positionalArguments.first as String,
    );

    when(() => mockLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
          tag: any(named: 'tag'),
        )).thenReturn(null);

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

  Future<void> pumpColorsLayout(
    WidgetTester tester, {
    KidsState? state,
    int level = 2,
    double width = 390,
    double height = 844,
    ThemeMode themeMode = ThemeMode.light,
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
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: Scaffold(
                body: KidsColorsLayout(
                  level: level,
                  title: 'Art Studio Colors',
                  primaryColor: Colors.deepOrange,
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('KidsColorsLayout - Initial Rendering & Aesthetics', () {
    testWidgets('renders easel canvas, instructions, emoji, and paint tubes for color quests',
        (tester) async {
      await pumpColorsLayout(tester, state: testLoadedColorState);

      // Verify instruction text is displayed in speech bubble
      expect(
        find.text('A stop sign tells cars to stop. What color is it?'),
        findsOneWidget,
      );

      // Verify prompt banner text
      expect(
        find.text('Tap or drag the correct color to the canvas!'),
        findsOneWidget,
      );

      // Verify paint tube options rendered
      expect(find.byKey(const ValueKey('colors_option_Red')), findsOneWidget);
      expect(find.byKey(const ValueKey('colors_option_Yellow')), findsOneWidget);
      expect(find.byKey(const ValueKey('colors_option_Blue')), findsOneWidget);

      // Verify water drop icons inside paint tubes
      expect(find.byIcon(Icons.water_drop_rounded), findsNWidgets(3));

      // Verify audio replay button
      expect(find.byKey(const ValueKey('colors_audio_replay_btn')), findsOneWidget);
    });

    testWidgets('renders object cards for object classification quests',
        (tester) async {
      await pumpColorsLayout(tester, state: testLoadedObjectState);

      // Verify object options rendered
      expect(find.byKey(const ValueKey('colors_option_Lemon')), findsOneWidget);
      expect(find.byKey(const ValueKey('colors_option_Grass')), findsOneWidget);
      expect(find.byKey(const ValueKey('colors_option_Tomato')), findsOneWidget);

      // Verify prompt adapts to object quest
      expect(
        find.text('Tap or drag the correct item to the easel!'),
        findsOneWidget,
      );
    });

    testWidgets('renders cleanly in dark mode without contrast issues',
        (tester) async {
      await pumpColorsLayout(
        tester,
        state: testLoadedColorState,
        themeMode: ThemeMode.dark,
      );

      expect(find.byType(KidsColorsLayout), findsOneWidget);
      expect(
        find.text('A stop sign tells cars to stop. What color is it?'),
        findsOneWidget,
      );
    });
  });

  group('KidsColorsLayout - Audio Scaffolding', () {
    testWidgets('tapping easel audio button replays question instruction via TTS',
        (tester) async {
      await pumpColorsLayout(tester, state: testLoadedColorState);

      final audioBtn = find.byKey(const ValueKey('colors_audio_replay_btn'));
      expect(audioBtn, findsOneWidget);

      await tester.tap(audioBtn);
      await tester.pump();

      verify(() => mockTTSService.speak(
            'A stop sign tells cars to stop. What color is it?',
            force: true,
          )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping option speaker button pronounces color name via TTS',
        (tester) async {
      await pumpColorsLayout(tester, state: testLoadedColorState);

      final redSpeaker = find.byKey(const ValueKey('colors_speaker_Red'));
      expect(redSpeaker, findsOneWidget);

      await tester.tap(redSpeaker);
      await tester.pump();

      verify(() => mockTTSService.speak('Red', force: true)).called(1);
      verify(() => mockHapticService.selection()).called(1);
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });
  });

  group('KidsColorsLayout - Dual Interaction (Tap & Drag)', () {
    testWidgets('instant tap-to-answer correct option dispatches SubmitKidsAnswer(true) and success haptics',
        (tester) async {
      await pumpColorsLayout(tester, state: testLoadedColorState);

      final redOption = find.byKey(const ValueKey('colors_option_Red'));
      await tester.tap(redOption);
      await tester.pump();

      verify(() => mockHapticService.success()).called(1);
      verifyNever(() => mockHapticService.error());
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('instant tap-to-answer incorrect option dispatches SubmitKidsAnswer(false), error haptics and TTS pronunciation',
        (tester) async {
      await pumpColorsLayout(tester, state: testLoadedColorState);

      final yellowOption = find.byKey(const ValueKey('colors_option_Yellow'));
      await tester.tap(yellowOption);
      await tester.pump();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockTTSService.speak('Yellow')).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
    });

    testWidgets('drag-and-drop correct paint tube to easel canvas triggers SubmitKidsAnswer(true)',
        (tester) async {
      await pumpColorsLayout(tester, state: testLoadedColorState);

      final draggableFinder = find.byWidgetPredicate(
        (w) => w is Draggable<String> && w.data == 'Red',
      );
      final dragTargetFinder = find.byType(DragTarget<String>);

      expect(draggableFinder, findsOneWidget);
      expect(dragTargetFinder, findsOneWidget);

      final dragGesture = await tester.startGesture(tester.getCenter(draggableFinder));
      await tester.pump();

      // Move over the drag target canvas
      await dragGesture.moveTo(tester.getCenter(dragTargetFinder));
      await tester.pump();

      // Drop
      await dragGesture.up();
      await tester.pump();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('drag-and-drop incorrect paint tube to easel canvas triggers SubmitKidsAnswer(false)',
        (tester) async {
      await pumpColorsLayout(tester, state: testLoadedColorState);

      final draggableFinder = find.byWidgetPredicate(
        (w) => w is Draggable<String> && w.data == 'Blue',
      );
      final dragTargetFinder = find.byType(DragTarget<String>);

      final dragGesture = await tester.startGesture(tester.getCenter(draggableFinder));
      await tester.pump();

      await dragGesture.moveTo(tester.getCenter(dragTargetFinder));
      await tester.pump();

      await dragGesture.up();
      await tester.pump();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockTTSService.speak('Blue')).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
    });

    testWidgets('locks interaction when quest is already answered',
        (tester) async {
      const answeredState = KidsLoaded(
        quests: [testColorQuest],
        originalTotalQuests: 1,
        gameType: 'colors',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpColorsLayout(tester, state: answeredState);

      final redOption = find.byKey(const ValueKey('colors_option_Red'));
      await tester.tap(redOption, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });
  });

  group('KidsColorsLayout - Small Screen (320dp) & Complex Curriculum Safety', () {
    testWidgets('renders 4 mineral options on compact 320dp width without RenderFlex overflow',
        (tester) async {
      await pumpColorsLayout(
        tester,
        state: testLoadedFourOptionsState,
        level: 190,
        width: 320,
        height: 568,
      );

      // Verify all 4 gemstone options are visible
      expect(find.byKey(const ValueKey('colors_option_Sapphire')), findsOneWidget);
      expect(find.byKey(const ValueKey('colors_option_Emerald')), findsOneWidget);
      expect(find.byKey(const ValueKey('colors_option_Ruby')), findsOneWidget);
      expect(find.byKey(const ValueKey('colors_option_Topaz')), findsOneWidget);

      // Verify zero overflow exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping option on 320dp screen still triggers correct answer flow',
        (tester) async {
      await pumpColorsLayout(
        tester,
        state: testLoadedFourOptionsState,
        level: 190,
        width: 320,
        height: 568,
      );

      final sapphireOption = find.byKey(const ValueKey('colors_option_Sapphire'));
      await tester.tap(sapphireOption);
      await tester.pump();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });
  });
}
