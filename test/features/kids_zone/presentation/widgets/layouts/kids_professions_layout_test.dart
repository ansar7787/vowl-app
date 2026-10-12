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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_professions_layout.dart';

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
    id: 'KIDS_PROFESSIONS_L2_Q1',
    gameType: 'professions',
    level: 2,
    instruction:
        'Who helps children learn to read, write, and count in a classroom?',
    question: '?',
    correctAnswer: 'Teacher',
    options: ['Baker', 'Teacher', 'Firefighter'],
    hint: 'Think about who is at the front of the room during lessons.',
    emoji: '🏫',
    explanation:
        'Teachers plan lessons and guide children as they practice new skills.',
    funFact: "Many teachers learn each student's name quickly.",
  );

  const testQuestLongOptions = KidsQuest(
    id: 'KIDS_PROFESSIONS_L191_Q1',
    gameType: 'professions',
    level: 191,
    instruction:
        'On a stormy night, a volunteer helps a lost hiker using a map and radio. Which job matches?',
    question: '?',
    correctAnswer: 'Mountain Rescue Volunteer',
    options: [
      'Mountain Rescue Volunteer',
      'Mountain Weather Forecaster',
      'Campsite Kitchen Cook',
    ],
    hint: 'Think about navigation, safety gear, and teamwork combined.',
    emoji: '🏂',
    explanation: 'Rescue work combines map reading and first aid.',
    funFact: 'Mountain rescue teams often include volunteers.',
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuestShortOptions],
    originalTotalQuests: 1,
    gameType: 'professions',
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

    when(() => mockLocaleService.tr(any())).thenAnswer((inv) => inv.positionalArguments.first as String);

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

  Future<void> pumpProfessionsLayout(
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
                child: const KidsProfessionsLayout(
                  level: 2,
                  title: 'Professions',
                  primaryColor: Color(0xFF0D9488),
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

  group('KidsProfessionsLayout Production Audit Tests', () {
    testWidgets('renders storefront, dispatch header, scenario, and 3 clipboards',
        (tester) async {
      await pumpProfessionsLayout(tester);

      expect(find.text('Community Helpers'), findsOneWidget);
      expect(
        find.text(
          'Who helps children learn to read, write, and count in a classroom?',
        ),
        findsWidgets,
      );
      expect(find.text('Teacher'), findsOneWidget);
      expect(find.text('Baker'), findsOneWidget);
      expect(find.text('Firefighter'), findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);
    });

    testWidgets('supports accessible tap-to-answer submission (dual interaction)',
        (tester) async {
      await pumpProfessionsLayout(tester);

      // Tap the correct clipboard
      await tester.tap(find.text('Teacher'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Teacher', force: true)).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockLogger.debug(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('supports drag-and-drop to career storefront target',
        (tester) async {
      await pumpProfessionsLayout(tester);

      final teacherFinder = find.text('Teacher');
      final storefrontFinder = find.byType(DragTarget<String>);

      expect(teacherFinder, findsOneWidget);
      expect(storefrontFinder, findsOneWidget);

      final dragLocation = tester.getCenter(storefrontFinder);
      final gesture = await tester.startGesture(tester.getCenter(teacherFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('replays scenario audio when Listen button is tapped',
        (tester) async {
      await pumpProfessionsLayout(tester);

      await tester.tap(find.text('Listen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(
        () => mockTTSService.speak(
          'Who helps children learn to read, write, and count in a classroom?',
          force: true,
        ),
      ).called(1);
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockLogger.debug(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('pronounces career name when clipboard speaker button is tapped',
        (tester) async {
      await pumpProfessionsLayout(tester);

      final hearButton = find.bySemanticsLabel('Hear Baker pronounced');
      expect(hearButton, findsOneWidget);

      await tester.tap(hearButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Baker', force: true)).called(1);
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockLogger.debug(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('displays celebratory hero badge upon correct answer',
        (tester) async {
      const correctState = KidsLoaded(
        quests: [testQuestShortOptions],
        originalTotalQuests: 1,
        gameType: 'professions',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpProfessionsLayout(tester, state: correctState);

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('🏫'), findsOneWidget);
      expect(find.text('Teacher'), findsNWidgets(2)); // One in hero banner, one in options
    });

    testWidgets('renders wide dispatch cards for long options without clipping',
        (tester) async {
      const longOptionsState = KidsLoaded(
        quests: [testQuestLongOptions],
        originalTotalQuests: 1,
        gameType: 'professions',
        level: 191,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpProfessionsLayout(tester, state: longOptionsState);

      expect(find.text('Mountain Rescue Volunteer'), findsOneWidget);
      expect(find.text('Mountain Weather Forecaster'), findsOneWidget);
      expect(find.text('Campsite Kitchen Cook'), findsOneWidget);
    });

    testWidgets('dims a wrong distractor when lifeline hintUsed is true',
        (tester) async {
      const hintState = KidsLoaded(
        quests: [testQuestShortOptions],
        originalTotalQuests: 1,
        gameType: 'professions',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await pumpProfessionsLayout(tester, state: hintState);

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();

      expect(opacities.contains(0.35), isTrue);
    });

    testWidgets('locks interaction when question is already answered',
        (tester) async {
      const answeredState = KidsLoaded(
        quests: [testQuestShortOptions],
        originalTotalQuests: 1,
        gameType: 'professions',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpProfessionsLayout(tester, state: answeredState);

      // Tapping option should not submit again
      await tester.tap(find.text('Teacher').last, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('renders without overflow on narrow 320dp screen',
        (tester) async {
      await pumpProfessionsLayout(tester, width: 320, height: 600);

      expect(tester.takeException(), isNull);
      expect(find.text('Community Helpers'), findsOneWidget);
    });

    testWidgets('renders without overflow on large 430dp screen',
        (tester) async {
      await pumpProfessionsLayout(tester, width: 430, height: 932);

      expect(tester.takeException(), isNull);
      expect(find.text('Community Helpers'), findsOneWidget);
    });
  });

  group('StoryService & GameInstructionService Integration Tests', () {
    test('StoryService professions scripts provide inspirational milestones', () {
      final beats = StoryServiceImpl.kidsScripts['professions']!;
      expect(beats, isNotEmpty);
      expect(beats.length, greaterThanOrEqualTo(2));
      expect(beats.first.contains('jobs') || beats.first.contains('careers'), isTrue);
    });

    testWidgets('GameInstructionService professions briefing matches game mechanics', (tester) async {
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
        'professions',
        level: 1,
      );
      expect(briefing.title, 'Community Helpers');
      expect(briefing.rules.length, greaterThanOrEqualTo(2));
      expect(briefing.icon, Icons.work_rounded);
    });
  });
}

