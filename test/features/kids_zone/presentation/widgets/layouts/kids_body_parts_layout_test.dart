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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_body_parts_layout.dart';

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

  const testQuestShort = KidsQuest(
    id: 'KIDS_BODY_PARTS_L2_Q1',
    gameType: 'body_parts',
    level: 2,
    instruction:
        'You are reading a picture book. Which body part do you use to look at the pictures?',
    question: '?',
    correctAnswer: 'Eyes 👀',
    options: ['Eyes 👀', 'Nose 👃', 'Hair 🦱'],
    hint: 'You have two of them, and they sit just above your nose.',
    emoji: '👀',
    explanation:
        'Eyes take in light from the world around you, so you can see colors, shapes, and pictures.',
    funFact:
        'You blink about 15 to 20 times every minute, and each blink keeps your eyes moist.',
  );

  const testQuestLong = KidsQuest(
    id: 'KIDS_BODY_PARTS_L191_Q2',
    gameType: 'body_parts',
    level: 191,
    instruction:
        'A beautiful song gives you goosebumps. Which chain of parts is working, in order?',
    question: '?',
    correctAnswer: 'Ears → brain → skin 🎵',
    options: [
      'Ears → brain → skin 🎵',
      'Eyes → heart → feet 👀',
      'Skin → brain → ears 🤚',
    ],
    hint: 'The sound arrives first, and the goosebumps appear last.',
    emoji: '🎵',
    explanation:
        'Your ears catch the music, your brain reacts to it, and the brain sends a signal.',
    funFact: 'About half of all people say they sometimes get chills from music.',
  );

  const testLoadedStateShort = KidsLoaded(
    quests: [testQuestShort],
    originalTotalQuests: 1,
    gameType: 'body_parts',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedStateLong = KidsLoaded(
    quests: [testQuestLong],
    originalTotalQuests: 1,
    gameType: 'body_parts',
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

    when(() => mockKidsBloc.state).thenReturn(testLoadedStateShort);
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

  Future<void> pumpBodyPartsLayout(
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
                body: KidsBodyPartsLayout(
                  level: 2,
                  title: 'Body Parts',
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

  group('KidsBodyPartsLayout - Component Rendering', () {
    testWidgets('renders X-Ray scanner lightbox with riddle and audio button',
        (tester) async {
      await pumpBodyPartsLayout(tester);

      expect(find.text('X-RAY SCANNER'), findsOneWidget);
      expect(find.text('BODY CLUE'), findsOneWidget);
      expect(
        find.textContaining('You are reading a picture book'),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('body_parts_audio_replay_btn')),
        findsOneWidget,
      );
    });

    testWidgets('renders 3 pill band-aid options for short body parts',
        (tester) async {
      await pumpBodyPartsLayout(tester);

      expect(find.text('Eyes 👀'), findsOneWidget);
      expect(find.text('Nose 👃'), findsOneWidget);
      expect(find.text('Hair 🦱'), findsOneWidget);
    });

    testWidgets('renders wide bandage strips when options are sensory chains',
        (tester) async {
      await pumpBodyPartsLayout(tester, state: testLoadedStateLong);

      expect(find.text('Ears → brain → skin 🎵'), findsOneWidget);
      expect(find.text('Eyes → heart → feet 👀'), findsOneWidget);
      expect(find.text('Skin → brain → ears 🤚'), findsOneWidget);
    });
  });

  group('KidsBodyPartsLayout - Interaction & Submission', () {
    testWidgets(
        'tap on correct band-aid submits SubmitKidsAnswer(true) and speaks part',
        (tester) async {
      await pumpBodyPartsLayout(tester);

      final correctOption = find.text('Eyes 👀');
      expect(correctOption, findsOneWidget);
      await tester.ensureVisible(correctOption);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockTTSService.speak('Eyes', force: true)).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets(
        'tap on incorrect band-aid submits SubmitKidsAnswer(false) and triggers error haptic',
        (tester) async {
      await pumpBodyPartsLayout(tester);

      final wrongOption = find.text('Hair 🦱');
      expect(wrongOption, findsOneWidget);
      await tester.ensureVisible(wrongOption);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
      verify(() => mockTTSService.speak('Hair', force: true)).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('tapping speaker icon on band-aid pronounces part without submitting',
        (tester) async {
      await pumpBodyPartsLayout(tester);

      final hearButton = find.byKey(const ValueKey('speaker_bandaid_Eyes 👀'));
      expect(hearButton, findsOneWidget);
      await tester.ensureVisible(hearButton);

      await tester.tap(hearButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Eyes', force: true)).called(1);
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('tapping audio replay button in lightbox invokes TTS',
        (tester) async {
      await pumpBodyPartsLayout(tester);

      final replayButton =
          find.byKey(const ValueKey('body_parts_audio_replay_btn'));
      expect(replayButton, findsOneWidget);
      await tester.ensureVisible(replayButton);

      await tester.tap(replayButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak(any(), force: true)).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('drag-and-drop band-aid to X-Ray lightbox submits answer',
        (tester) async {
      await pumpBodyPartsLayout(tester);

      final eyesFinder = find.text('Eyes 👀');
      final xrayFinder = find.byType(DragTarget<String>);

      expect(eyesFinder, findsOneWidget);
      expect(xrayFinder, findsOneWidget);
      await tester.ensureVisible(eyesFinder);

      final dragLocation = tester.getCenter(xrayFinder);
      final gesture = await tester.startGesture(tester.getCenter(eyesFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });
  });

  group('KidsBodyPartsLayout - Feedback & Lifeline Scaffolding', () {
    testWidgets(
        'displays celebratory reveal with emoji and answer when answered correctly',
        (tester) async {
      const correctState = KidsLoaded(
        quests: [testQuestShort],
        originalTotalQuests: 1,
        gameType: 'body_parts',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpBodyPartsLayout(tester, state: correctState);

      expect(find.text('👀'), findsWidgets);
      expect(find.text('Eyes 👀'), findsWidgets);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
    });

    testWidgets('hint lifeline dims distractor band-aid when hintUsed is true',
        (tester) async {
      const hintState = KidsLoaded(
        quests: [testQuestShort],
        originalTotalQuests: 1,
        gameType: 'body_parts',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await pumpBodyPartsLayout(tester, state: hintState);

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      final hasDimmedDistractor = opacities.any((o) => o.opacity == 0.35);
      expect(hasDimmedDistractor, isTrue);
    });
  });

  group('KidsBodyPartsLayout - Responsive Layout Safety', () {
    testWidgets('renders cleanly without overflow on narrow 320dp screen',
        (tester) async {
      await pumpBodyPartsLayout(tester, width: 320, height: 600);

      expect(find.text('X-RAY SCANNER'), findsOneWidget);
      expect(find.text('Eyes 👀'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow on tablet 600dp screen',
        (tester) async {
      await pumpBodyPartsLayout(tester, width: 600, height: 960);

      expect(find.text('X-RAY SCANNER'), findsOneWidget);
      expect(find.text('Eyes 👀'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

