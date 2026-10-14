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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_day_night_layout.dart';

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

  const testDayNightQuest = KidsQuest(
    id: 'KIDS_DAY_NIGHT_L2_Q1',
    gameType: 'day_night',
    level: 2,
    instruction:
        'The Sun is shining high above the playground, and the slide feels warm. Is it daytime or nighttime?',
    question: '?',
    correctAnswer: 'Daytime',
    options: ['Nighttime', 'Daytime'],
    hint: 'What is lighting up the sky so brightly?',
    emoji: '🛝',
    explanation:
        'When the Sun is up and shining, we have daylight. That is what makes it daytime.',
    funFact:
        'The Sun is a star. It looks much bigger than the other stars because it is so much closer to us.',
  );

  const testNightQuest = KidsQuest(
    id: 'KIDS_DAY_NIGHT_L2_Q2',
    gameType: 'day_night',
    level: 2,
    instruction:
        'Mia looks out her window and sees the Moon and lots of tiny twinkling stars. When is she looking?',
    question: '?',
    correctAnswer: 'Nighttime',
    options: ['Nighttime', 'Daytime'],
    hint: 'Picture the color of the sky behind those twinkling stars.',
    emoji: '🪟',
    explanation:
        'Stars and the Moon are easiest to spot against a dark sky, and the sky is dark at night.',
    funFact:
        'Stars are far-away suns. They look like tiny dots only because they are very, very far from Earth.',
  );

  const testFourOptionsQuest = KidsQuest(
    id: 'KIDS_DAY_NIGHT_L190_Q3',
    gameType: 'day_night',
    level: 190,
    instruction:
        'During which celestial phase is the lunar surface fully bathed in brilliant solar reflection?',
    question: '?',
    correctAnswer: 'Full Moon',
    options: ['New Moon', 'Full Moon', 'Crescent Moon', 'Quarter Moon'],
    hint: 'Think of a complete shining circle in the night sky.',
    emoji: '🌕',
    explanation:
        'A full moon occurs when the entire near side of the Moon is illuminated by the Sun.',
    funFact: 'A full moon occurs roughly once every 29.5 days.',
  );

  const testLoadedDayNightState = KidsLoaded(
    quests: [testDayNightQuest],
    originalTotalQuests: 1,
    gameType: 'day_night',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedNightState = KidsLoaded(
    quests: [testNightQuest],
    originalTotalQuests: 1,
    gameType: 'day_night',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedFourOptionsState = KidsLoaded(
    quests: [testFourOptionsQuest],
    originalTotalQuests: 1,
    gameType: 'day_night',
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

    when(() => mockKidsBloc.state).thenReturn(testLoadedDayNightState);
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

  Future<void> pumpDayNightLayout(
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
                body: KidsDayNightLayout(
                  level: level,
                  title: 'Sky Observatory',
                  primaryColor: Colors.indigo,
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

  group('KidsDayNightLayout - Initial Rendering & Celestial Aesthetics', () {
    testWidgets('renders observatory sky view, stars, prompt banner, and celestial cards',
        (tester) async {
      await pumpDayNightLayout(tester, state: testLoadedDayNightState);

      // Verify instruction text rendered in header bubble
      expect(
        find.text(
          'The Sun is shining high above the playground, and the slide feels warm. Is it daytime or nighttime?',
        ),
        findsOneWidget,
      );

      // Verify prompt banner text
      expect(
        find.text('Tap or drag the correct sky card to the observatory!'),
        findsOneWidget,
      );

      // Verify celestial cards rendered
      expect(find.byKey(const ValueKey('day_night_option_Daytime')), findsOneWidget);
      expect(find.byKey(const ValueKey('day_night_option_Nighttime')), findsOneWidget);

      // Verify sun and moon icons are present
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mode_night_rounded), findsOneWidget);

      // Verify audio replay button
      expect(find.byKey(const ValueKey('day_night_audio_replay_btn')), findsOneWidget);
    });

    testWidgets('renders nighttime quest with appropriate moon icon and question placeholder',
        (tester) async {
      await pumpDayNightLayout(tester, state: testLoadedNightState);

      expect(
        find.text(
          'Mia looks out her window and sees the Moon and lots of tiny twinkling stars. When is she looking?',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('day_night_option_Nighttime')), findsOneWidget);
      expect(find.byKey(const ValueKey('day_night_option_Daytime')), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without contrast issues',
        (tester) async {
      await pumpDayNightLayout(
        tester,
        state: testLoadedDayNightState,
        themeMode: ThemeMode.dark,
      );

      expect(find.byType(KidsDayNightLayout), findsOneWidget);
      expect(find.byKey(const ValueKey('day_night_option_Daytime')), findsOneWidget);
    });
  });

  group('KidsDayNightLayout - Audio Scaffolding', () {
    testWidgets('tapping sky view audio button replays question instruction via TTS',
        (tester) async {
      await pumpDayNightLayout(tester, state: testLoadedDayNightState);

      final audioBtn = find.byKey(const ValueKey('day_night_audio_replay_btn'));
      expect(audioBtn, findsOneWidget);

      await tester.tap(audioBtn);
      await tester.pump();

      verify(() => mockTTSService.speak(
            'The Sun is shining high above the playground, and the slide feels warm. Is it daytime or nighttime?',
            force: true,
          )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping option speaker button pronounces celestial name via TTS without submitting',
        (tester) async {
      await pumpDayNightLayout(tester, state: testLoadedDayNightState);

      final daytimeSpeaker = find.byKey(const ValueKey('day_night_speaker_Daytime'));
      expect(daytimeSpeaker, findsOneWidget);

      await tester.tap(daytimeSpeaker);
      await tester.pump();

      verify(() => mockTTSService.speak('Daytime', force: true)).called(1);
      verify(() => mockHapticService.selection()).called(1);
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });
  });

  group('KidsDayNightLayout - Dual Interaction (Tap & Drag)', () {
    testWidgets('instant tap-to-answer correct option dispatches SubmitKidsAnswer(true) and success haptics',
        (tester) async {
      await pumpDayNightLayout(tester, state: testLoadedDayNightState);

      final daytimeOption = find.byKey(const ValueKey('day_night_option_Daytime'));
      await tester.tap(daytimeOption);
      await tester.pump();

      verify(() => mockHapticService.success()).called(1);
      verifyNever(() => mockHapticService.error());
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('instant tap-to-answer incorrect option dispatches SubmitKidsAnswer(false), error haptics and TTS pronunciation',
        (tester) async {
      await pumpDayNightLayout(tester, state: testLoadedDayNightState);

      final nighttimeOption = find.byKey(const ValueKey('day_night_option_Nighttime'));
      await tester.tap(nighttimeOption);
      await tester.pump();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockTTSService.speak('Nighttime')).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
    });

    testWidgets('drag-and-drop correct celestial card onto observatory sky view triggers SubmitKidsAnswer(true)',
        (tester) async {
      await pumpDayNightLayout(tester, state: testLoadedDayNightState);

      final draggableFinder = find.byWidgetPredicate(
        (w) => w is Draggable<String> && w.data == 'Daytime',
      );
      final dragTargetFinder = find.byType(DragTarget<String>);

      expect(draggableFinder, findsOneWidget);
      expect(dragTargetFinder, findsOneWidget);

      final dragGesture = await tester.startGesture(tester.getCenter(draggableFinder));
      await tester.pump();

      // Move over the drag target observatory
      await dragGesture.moveTo(tester.getCenter(dragTargetFinder));
      await tester.pump();

      // Drop
      await dragGesture.up();
      await tester.pump();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('drag-and-drop incorrect celestial card onto observatory sky view triggers SubmitKidsAnswer(false)',
        (tester) async {
      await pumpDayNightLayout(tester, state: testLoadedDayNightState);

      final draggableFinder = find.byWidgetPredicate(
        (w) => w is Draggable<String> && w.data == 'Nighttime',
      );
      final dragTargetFinder = find.byType(DragTarget<String>);

      final dragGesture = await tester.startGesture(tester.getCenter(draggableFinder));
      await tester.pump();

      await dragGesture.moveTo(tester.getCenter(dragTargetFinder));
      await tester.pump();

      await dragGesture.up();
      await tester.pump();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockTTSService.speak('Nighttime')).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
    });

    testWidgets('locks interaction when quest is already answered',
        (tester) async {
      const answeredState = KidsLoaded(
        quests: [testDayNightQuest],
        originalTotalQuests: 1,
        gameType: 'day_night',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpDayNightLayout(tester, state: answeredState);

      final daytimeOption = find.byKey(const ValueKey('day_night_option_Daytime'));
      await tester.tap(daytimeOption, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });
  });

  group('KidsDayNightLayout - Small Screen (320dp) & Complex Curriculum Safety', () {
    testWidgets('renders 4 lunar phase options on compact 320dp width without RenderFlex overflow',
        (tester) async {
      await pumpDayNightLayout(
        tester,
        state: testLoadedFourOptionsState,
        level: 190,
        width: 320,
        height: 568,
      );

      // Verify all 4 lunar options are visible
      expect(find.byKey(const ValueKey('day_night_option_New Moon')), findsOneWidget);
      expect(find.byKey(const ValueKey('day_night_option_Full Moon')), findsOneWidget);
      expect(find.byKey(const ValueKey('day_night_option_Crescent Moon')), findsOneWidget);
      expect(find.byKey(const ValueKey('day_night_option_Quarter Moon')), findsOneWidget);

      // Verify zero overflow exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping option on 320dp screen still triggers correct answer flow',
        (tester) async {
      await pumpDayNightLayout(
        tester,
        state: testLoadedFourOptionsState,
        level: 190,
        width: 320,
        height: 568,
      );

      final fullMoonOption = find.byKey(const ValueKey('day_night_option_Full Moon'));
      await tester.tap(fullMoonOption);
      await tester.pump();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });
  });
}

