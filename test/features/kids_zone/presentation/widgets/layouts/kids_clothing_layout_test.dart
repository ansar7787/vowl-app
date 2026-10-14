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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_clothing_layout.dart';

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
    id: 'KIDS_CLOTHING_L2_Q1',
    gameType: 'clothing',
    level: 2,
    instruction:
        'Mia pulls something over her head and pushes her arms through the sleeves. What is she putting on?',
    question: '?',
    correctAnswer: 'Shirt 👕',
    options: ['Socks 🧦', 'Pants 👖', 'Shirt 👕'],
    hint: 'It covers the top half of your body.',
    emoji: '👕',
    explanation:
        'A shirt covers your chest, back, and usually your arms. Pants and socks go on the bottom half.',
    funFact:
        'Many shirts have a small tag inside the neck that tells you the size and how to wash it.',
  );

  const testQuestFourOptions = KidsQuest(
    id: 'KIDS_CLOTHING_L2_Q2',
    gameType: 'clothing',
    level: 2,
    instruction:
        'It is a freezing winter morning outside! Which warm outfit should Lucas put on first?',
    question: '?',
    correctAnswer: 'Warm Sweater 🧥',
    options: [
      'Flip-flops 🩴',
      'Swimsuit 🩱',
      'Warm Sweater 🧥',
      'Sun Hat 👒',
    ],
    hint: 'Choose the cozy clothing that protects you from cold wind.',
    emoji: '🧥',
    explanation: 'A warm sweater traps heat to keep your body warm in winter.',
    funFact: 'Wool sweaters are made from sheep fleece.',
  );

  const testLoadedStateShort = KidsLoaded(
    quests: [testQuestShort],
    originalTotalQuests: 1,
    gameType: 'clothing',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedStateFourOptions = KidsLoaded(
    quests: [testQuestFourOptions],
    originalTotalQuests: 1,
    gameType: 'clothing',
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

  Future<void> pumpClothingLayout(
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
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: KidsClothingLayout(
                level: 2,
                title: 'Kids Clothing',
                primaryColor: Color(0xFFF59E0B),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('KidsClothingLayout - Component Rendering', () {
    testWidgets(
        'renders Boutique Wardrobe closet with riddle and audio button',
        (tester) async {
      await pumpClothingLayout(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Boutique Wardrobe'), findsOneWidget);
      expect(
        find.text(
            'Mia pulls something over her head and pushes her arms through the sleeves. What is she putting on?'),
        findsWidgets,
      );
      expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);
      expect(find.text('Hang matching clothes here'), findsOneWidget);
    });

    testWidgets(
        'renders 3 clothing hanger options on single closet rod for concise options',
        (tester) async {
      await pumpClothingLayout(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Socks'), findsOneWidget);
      expect(find.text('Pants'), findsOneWidget);
      expect(find.text('Shirt'), findsOneWidget);

      expect(find.byType(Draggable<String>), findsNWidgets(3));
    });

    testWidgets(
        'renders 4 clothing hanger options across multi-tier closet racks',
        (tester) async {
      await pumpClothingLayout(tester, state: testLoadedStateFourOptions);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Flip-flops'), findsOneWidget);
      expect(find.text('Swimsuit'), findsOneWidget);
      expect(find.text('Warm Sweater'), findsOneWidget);
      expect(find.text('Sun Hat'), findsOneWidget);

      expect(find.byType(Draggable<String>), findsNWidgets(4));
    });
  });

  group('KidsClothingLayout - Interaction & Submission', () {
    testWidgets(
        'tap on correct hanger submits SubmitKidsAnswer(true) and speaks option',
        (tester) async {
      await pumpClothingLayout(tester);
      await tester.pump(const Duration(milliseconds: 100));

      final correctOption =
          find.byKey(const ValueKey('clothing_option_Shirt 👕'));
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockTTSService.speak('Shirt 👕')).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets(
        'tap on incorrect hanger submits SubmitKidsAnswer(false) and triggers error haptic',
        (tester) async {
      await pumpClothingLayout(tester);
      await tester.pump(const Duration(milliseconds: 100));

      final incorrectOption =
          find.byKey(const ValueKey('clothing_option_Socks 🧦'));
      expect(incorrectOption, findsOneWidget);

      await tester.tap(incorrectOption);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
      verify(() => mockTTSService.speak('Socks 🧦')).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets(
        'tapping speaker icon on hanger tag pronounces clothing item without submitting',
        (tester) async {
      await pumpClothingLayout(tester);
      await tester.pump(const Duration(milliseconds: 100));

      final speakerFinder =
          find.byKey(const ValueKey('clothing_speaker_Shirt 👕'));
      expect(speakerFinder, findsOneWidget);

      await tester.tap(speakerFinder);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Shirt 👕')).called(1);
      verify(() => mockHapticService.selection()).called(1);
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets(
        'tapping audio replay button in closet invokes TTS',
        (tester) async {
      await pumpClothingLayout(tester);
      await tester.pump(const Duration(milliseconds: 100));

      final replayFinder =
          find.byKey(const ValueKey('clothing_audio_replay_btn'));
      expect(replayFinder, findsOneWidget);

      await tester.tap(replayFinder);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak(testQuestShort.instruction)).called(1);
    });

    testWidgets(
        'drag-and-drop clothing hanger to wardrobe closet submits answer',
        (tester) async {
      await pumpClothingLayout(tester);
      await tester.pump(const Duration(milliseconds: 100));

      final draggableFinder = find.byType(Draggable<String>).first;
      final targetFinder = find.byType(DragTarget<String>);

      final gesture =
          await tester.startGesture(tester.getCenter(draggableFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(tester.getCenter(targetFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())))
          .called(1);
    });
  });

  group('KidsClothingLayout - Feedback & Lifeline Scaffolding', () {
    testWidgets(
        'displays celebratory reveal with emoji and answer when answered correctly',
        (tester) async {
      const answeredState = KidsLoaded(
        quests: [testQuestShort],
        originalTotalQuests: 1,
        gameType: 'clothing',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpClothingLayout(tester, state: answeredState);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('👕'), findsWidgets);
      expect(find.text('Shirt 👕'), findsOneWidget);
      expect(
        find.text(
            'A shirt covers your chest, back, and usually your arms. Pants and socks go on the bottom half.'),
        findsWidgets,
      );
    });

    testWidgets(
        'hint lifeline dims an incorrect distractor hanger tag when hintUsed is true',
        (tester) async {
      const hintState = KidsLoaded(
        quests: [testQuestShort],
        originalTotalQuests: 1,
        gameType: 'clothing',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await pumpClothingLayout(tester, state: hintState);
      await tester.pump(const Duration(milliseconds: 100));

      // The first incorrect distractor is 'Socks 🧦' (index 0).
      // When dimmed, its Draggable is replaced with the non-draggable interactive card,
      // and Draggable count reduces from 3 to 2.
      expect(find.byType(Draggable<String>), findsNWidgets(2));
    });
  });

  group('KidsClothingLayout - Responsive Layout Safety', () {
    testWidgets('renders cleanly without overflow on narrow 320dp screen',
        (tester) async {
      await pumpClothingLayout(
        tester,
        width: 320,
        height: 568,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Boutique Wardrobe'), findsOneWidget);
      expect(find.byType(DragTarget<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow on tablet 600dp screen',
        (tester) async {
      await pumpClothingLayout(
        tester,
        width: 600,
        height: 900,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Boutique Wardrobe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

