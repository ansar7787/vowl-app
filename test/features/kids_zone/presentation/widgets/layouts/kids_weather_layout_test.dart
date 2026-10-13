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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_weather_layout.dart';

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

  const testQuestShortOptions = KidsQuest(
    id: 'KIDS_WEATHER_L2_Q1',
    gameType: 'weather',
    level: 2,
    instruction:
        'Ravi wakes up and bright light is pouring through the gap in his bedroom curtains.',
    question: 'What kind of day is it most likely to be outside?',
    correctAnswer: 'Sunny',
    options: ['Foggy', 'Sunny', 'Rainy', 'Snowy'],
    hint: 'Picture what makes a bedroom bright early in the morning.',
    emoji: '☀️',
    explanation:
        'Bright light pouring in means the Sun is shining with little in the way.',
    funFact:
        'The Sun is a star so big that more than a million Earths could fit inside it.',
  );

  const testQuestLongOptions = KidsQuest(
    id: 'KIDS_WEATHER_L91_Q2',
    gameType: 'weather',
    level: 91,
    instruction: 'A teacher asks the class what makes the booming sound of thunder.',
    question: 'What causes thunder?',
    correctAnswer: 'Lightning heats air that suddenly expands',
    options: [
      'Lightning heats air that suddenly expands',
      'Wind whistling through narrow canyons',
      'Raindrops hitting the ground very hard',
      'Clouds crashing into each other overhead',
    ],
    hint: 'Imagine what lightning does to the air around it.',
    emoji: '💥',
    explanation:
        'Lightning heats the air around it in a split second, and the air bursts outward.',
    funFact: 'Thunder can sometimes be heard from ten kilometres away or more.',
  );

  const testLoadedStateShort = KidsLoaded(
    quests: [testQuestShortOptions],
    originalTotalQuests: 1,
    gameType: 'weather',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedStateLong = KidsLoaded(
    quests: [testQuestLongOptions],
    originalTotalQuests: 1,
    gameType: 'weather',
    level: 91,
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

    when(() => mockKidsBloc.state).thenReturn(testLoadedStateShort);
    when(() => mockKidsBloc.stream).thenAnswer((_) => const Stream<KidsState>.empty());

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
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockTTSService.speak(any(), force: any(named: 'force')))
        .thenAnswer((_) async => true);
    when(() => mockTTSService.stop()).thenAnswer((_) => Future.value());
    when(() => mockTTSService.isNarrationEnabled()).thenAnswer((_) async => false);

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    when(() => mockAudioService.playLevelCompleteSFX()).thenAnswer((_) async {});

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

  Future<void> pumpWeatherLayout(
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
              home: const Scaffold(
                body: KidsWeatherLayout(
                  level: 2,
                  title: 'Weather',
                  primaryColor: Color(0xFF38BDF8),
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

  group('KidsWeatherLayout - Component Rendering', () {
    testWidgets('renders forecast plaque with question text and audio button', (tester) async {
      await pumpWeatherLayout(tester);

      expect(find.text('WEATHER CLUE'), findsOneWidget);
      expect(
        find.text('What kind of day is it most likely to be outside?'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);
    });

    testWidgets('renders 4 puffy weather cloud options for short vocabulary', (tester) async {
      await pumpWeatherLayout(tester);

      expect(find.text('Sunny'), findsOneWidget);
      expect(find.text('Foggy'), findsOneWidget);
      expect(find.text('Rainy'), findsOneWidget);
      expect(find.text('Snowy'), findsOneWidget);
    });

    testWidgets('renders wide sky banner plaques when options are sentences', (tester) async {
      await pumpWeatherLayout(tester, state: testLoadedStateLong);

      expect(
        find.text('Lightning heats air that suddenly expands'),
        findsOneWidget,
      );
      expect(
        find.text('Wind whistling through narrow canyons'),
        findsOneWidget,
      );
      expect(
        find.text('Raindrops hitting the ground very hard'),
        findsOneWidget,
      );
      expect(
        find.text('Clouds crashing into each other overhead'),
        findsOneWidget,
      );
    });
  });

  group('KidsWeatherLayout - Interaction & Submission', () {
    testWidgets('tap on correct cloud submits SubmitKidsAnswer(true) and speaks answer', (tester) async {
      await pumpWeatherLayout(tester);

      final sunnyOption = find.text('Sunny');
      expect(sunnyOption, findsOneWidget);
      await tester.ensureVisible(sunnyOption);

      await tester.tap(sunnyOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockTTSService.speak('Sunny', force: true)).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('tap on incorrect cloud submits SubmitKidsAnswer(false) and triggers error haptic', (tester) async {
      await pumpWeatherLayout(tester);

      final foggyOption = find.text('Foggy');
      expect(foggyOption, findsOneWidget);
      await tester.ensureVisible(foggyOption);

      await tester.tap(foggyOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
      verify(() => mockTTSService.speak('Foggy', force: true)).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('tapping speaker icon on cloud pronounces option without submitting', (tester) async {
      await pumpWeatherLayout(tester);

      final hearButton = find.byKey(const ValueKey('speaker_cloud_Sunny'));
      expect(hearButton, findsOneWidget);
      await tester.ensureVisible(hearButton);

      await tester.tap(hearButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Sunny', force: true)).called(1);
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('drag-and-drop cloud to sky window submits answer', (tester) async {
      await pumpWeatherLayout(tester);

      final sunnyFinder = find.text('Sunny');
      final skyWindowFinder = find.byType(DragTarget<String>);

      expect(sunnyFinder, findsOneWidget);
      expect(skyWindowFinder, findsOneWidget);
      await tester.ensureVisible(sunnyFinder);

      final dragLocation = tester.getCenter(skyWindowFinder);
      final gesture = await tester.startGesture(tester.getCenter(sunnyFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });
  });

  group('KidsWeatherLayout - Feedback & Lifeline Scaffolding', () {
    testWidgets('displays celebratory reveal with emoji when answered correctly', (tester) async {
      const correctState = KidsLoaded(
        quests: [testQuestShortOptions],
        originalTotalQuests: 1,
        gameType: 'weather',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpWeatherLayout(tester, state: correctState);

      expect(find.text('☀️'), findsOneWidget);
      expect(find.text('Sunny'), findsWidgets);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
    });

    testWidgets('hint lifeline dims distractor cloud when hintUsed is true', (tester) async {
      const hintState = KidsLoaded(
        quests: [testQuestShortOptions],
        originalTotalQuests: 1,
        gameType: 'weather',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await pumpWeatherLayout(tester, state: hintState);

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      final hasDimmedDistractor = opacities.any((o) => o.opacity == 0.35);
      expect(hasDimmedDistractor, isTrue);
    });
  });

  group('KidsWeatherLayout - Responsive Layout Safety', () {
    testWidgets('renders cleanly without overflow on narrow 320dp screen', (tester) async {
      await pumpWeatherLayout(tester, width: 320, height: 600);

      expect(find.text('WEATHER CLUE'), findsOneWidget);
      expect(find.text('Sunny'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow on tablet 600dp screen', (tester) async {
      await pumpWeatherLayout(tester, width: 600, height: 960);

      expect(find.text('WEATHER CLUE'), findsOneWidget);
      expect(find.text('Sunny'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

