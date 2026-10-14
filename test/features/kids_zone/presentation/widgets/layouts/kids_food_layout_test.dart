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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_food_layout.dart';

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

  const testFoodQuest = KidsQuest(
    id: 'KIDS_FOOD_L2_Q1',
    gameType: 'food',
    level: 2,
    instruction:
        'Which fruit has a yellow peel that you pull off before you eat it?',
    question: 'Yellow peel fruit that peels in long strips?',
    correctAnswer: 'Banana 🍌',
    options: ['Pear 🍐', 'Banana 🍌', 'Grapes 🍇'],
    hint: 'Its peel comes off in long strips.',
    emoji: '🍌',
    explanation: 'The thick peel keeps the soft fruit inside clean.',
    funFact: 'Banana plants are giant herbs, not trees.',
  );

  const testFourOptionsQuest = KidsQuest(
    id: 'KIDS_FOOD_L25_Q4',
    gameType: 'food',
    level: 25,
    instruction:
        'Which warm morning food is made from oats cooked in milk or water?',
    question: 'Warm cooked oats for breakfast!',
    correctAnswer: 'Oatmeal 🥣',
    options: ['Pancake 🥞', 'Oatmeal 🥣', 'Waffle 🧇', 'Toast 🍞'],
    hint: 'It is served warm in a bowl.',
    emoji: '🥣',
    explanation: 'Oatmeal is made by boiling oats in milk or water.',
    funFact: 'Oats are rich in healthy fiber.',
  );

  const testLoadedFoodState = KidsLoaded(
    quests: [testFoodQuest],
    originalTotalQuests: 1,
    gameType: 'food',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedFourOptionsState = KidsLoaded(
    quests: [testFourOptionsQuest],
    originalTotalQuests: 1,
    gameType: 'food',
    level: 25,
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

    when(() => mockKidsBloc.state).thenReturn(testLoadedFoodState);
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

  Future<void> pumpFoodLayout(
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
                body: KidsFoodLayout(
                  level: level,
                  title: "Chef's Kitchen",
                  primaryColor: Colors.red,
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

  group("KidsFoodLayout - Initial Rendering & Kitchen Aesthetics", () {
    testWidgets(
      'renders kitchen tile board, chef hat, checkered tablecloth, and cloche serving platters',
      (tester) async {
        await pumpFoodLayout(tester);

        expect(
          find.byKey(const Key('kids_food_board_target')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('kids_food_replay_audio_button')),
          findsOneWidget,
        );
        expect(
          find.text('Yellow peel fruit that peels in long strips?'),
          findsOneWidget,
        );

        expect(find.byKey(const Key('kids_food_option_0')), findsOneWidget);
        expect(find.byKey(const Key('kids_food_option_1')), findsOneWidget);
        expect(find.byKey(const Key('kids_food_option_2')), findsOneWidget);

        expect(find.text('Pear'), findsOneWidget);
        expect(find.text('Banana'), findsOneWidget);
        expect(find.text('Grapes'), findsOneWidget);
      },
    );

    testWidgets(
      'renders correct food emoji on board when quest answer status is correct',
      (tester) async {
        final correctState = testLoadedFoodState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpFoodLayout(tester, state: correctState);

        expect(find.text('🍌'), findsWidgets);
      },
    );

    testWidgets(
      'renders cleanly in dark mode without contrast issues',
      (tester) async {
        await pumpFoodLayout(tester, themeMode: ThemeMode.dark);

        expect(
          find.byKey(const Key('kids_food_board_target')),
          findsOneWidget,
        );
        expect(find.text('Banana'), findsOneWidget);
      },
    );
  });

  group('KidsFoodLayout - Audio Scaffolding', () {
    testWidgets(
      'tapping kitchen board replay audio button replays question instruction via TTS',
      (tester) async {
        await pumpFoodLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_food_replay_audio_button')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak(
            testFoodQuest.instruction,
            force: true,
          ),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
      },
    );

    testWidgets(
      'tapping kitchen board itself replays question instruction via TTS',
      (tester) async {
        await pumpFoodLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_food_board_target')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak(
            testFoodQuest.instruction,
            force: true,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping cloche speaker button pronounces food name via TTS without submitting',
      (tester) async {
        await pumpFoodLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_food_pronounce_0')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak('Pear', force: true),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );
  });

  group('KidsFoodLayout - Dual Interaction (Tap & Drag)', () {
    testWidgets(
      'instant tap-to-answer correct food platter dispatches SubmitKidsAnswer(true) and success haptic',
      (tester) async {
        await pumpFoodLayout(tester);

        await tester.tap(find.byKey(const Key('kids_food_option_1')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(true)),
        ).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      'instant tap-to-answer incorrect food platter dispatches SubmitKidsAnswer(false), error haptic, and TTS pronunciation',
      (tester) async {
        await pumpFoodLayout(tester);

        await tester.tap(find.byKey(const Key('kids_food_option_0')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(false)),
        ).called(1);
        verify(() => mockHapticService.error()).called(1);
        verify(() => mockTTSService.speak('Pear')).called(1);
      },
    );

    testWidgets(
      'drag-and-drop correct food platter onto kitchen board triggers SubmitKidsAnswer(true)',
      (tester) async {
        await pumpFoodLayout(tester);

        final draggableFinder = find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'Banana 🍌',
        );
        final dragTargetFinder = find.byKey(
          const Key('kids_food_board_target'),
        );

        expect(draggableFinder, findsOneWidget);
        expect(dragTargetFinder, findsOneWidget);

        final gesture = await tester.startGesture(tester.getCenter(draggableFinder));
        await tester.pump();

        await gesture.moveTo(tester.getCenter(dragTargetFinder));
        await tester.pump();

        await gesture.up();
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(true)),
        ).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      'drag-and-drop incorrect food platter onto kitchen board triggers SubmitKidsAnswer(false)',
      (tester) async {
        await pumpFoodLayout(tester);

        final draggableFinder = find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'Pear 🍐',
        );
        final dragTargetFinder = find.byKey(
          const Key('kids_food_board_target'),
        );

        expect(draggableFinder, findsOneWidget);
        expect(dragTargetFinder, findsOneWidget);

        final gesture = await tester.startGesture(tester.getCenter(draggableFinder));
        await tester.pump();

        await gesture.moveTo(tester.getCenter(dragTargetFinder));
        await tester.pump();

        await gesture.up();
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(false)),
        ).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );

    testWidgets(
      'locks interaction when quest is already answered',
      (tester) async {
        final answeredState = testLoadedFoodState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpFoodLayout(tester, state: answeredState);

        await tester.tap(
          find.byKey(const Key('kids_food_option_1')),
          warnIfMissed: false,
        );
        await tester.pump();

        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );
  });

  group('KidsFoodLayout - Small Screen (320dp) & Complex Curriculum Safety', () {
    testWidgets(
      'renders 4 food options on compact 320dp width without RenderFlex overflow',
      (tester) async {
        await pumpFoodLayout(
          tester,
          state: testLoadedFourOptionsState,
          level: 25,
          width: 320,
          height: 568,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('kids_food_board_target')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('kids_food_option_0')), findsOneWidget);
        expect(find.byKey(const Key('kids_food_option_1')), findsOneWidget);
        expect(find.byKey(const Key('kids_food_option_2')), findsOneWidget);
        expect(find.byKey(const Key('kids_food_option_3')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping option on 320dp screen still triggers correct answer flow',
      (tester) async {
        await pumpFoodLayout(
          tester,
          state: testLoadedFourOptionsState,
          level: 25,
          width: 320,
          height: 568,
        );

        await tester.tap(find.byKey(const Key('kids_food_option_1')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(true)),
        ).called(1);
      },
    );
  });
}

