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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_emotions_layout.dart';

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

  const testEmotionsQuest = KidsQuest(
    id: 'KIDS_EMOTIONS_L2_Q1',
    gameType: 'emotions',
    level: 2,
    instruction:
        'Grandpa gives you a big push on the swing and you laugh so hard your cheeks hurt. What feeling is this?',
    question: 'Grandpa pushes you high on the swing and you laugh!',
    correctAnswer: 'Happy 😊',
    options: ['Angry 😠', 'Happy 😊', 'Sad 😢'],
    hint: 'Listen to what your voice is doing and look at your smile.',
    emoji: '😊',
    explanation: 'Laughing and smiling are signs of being happy.',
    funFact:
        'People laugh more when they are with other people than when they are alone.',
  );

  const testFourOptionsQuest = KidsQuest(
    id: 'KIDS_EMOTIONS_L15_Q4',
    gameType: 'emotions',
    level: 15,
    instruction:
        'You walk into a surprise birthday party and everyone jumps out shouting! What feeling is this?',
    question: 'Surprise party jump-out!',
    correctAnswer: 'Surprised 😲',
    options: ['Angry 😠', 'Surprised 😲', 'Sleepy 😴', 'Sad 😢'],
    hint: 'Your eyes open wide and your jaw drops open.',
    emoji: '😲',
    explanation: 'Surprise happens when something unexpected occurs.',
    funFact: 'Eyebrows naturally lift when you are surprised.',
  );

  const testLoadedEmotionsState = KidsLoaded(
    quests: [testEmotionsQuest],
    originalTotalQuests: 1,
    gameType: 'emotions',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedFourOptionsState = KidsLoaded(
    quests: [testFourOptionsQuest],
    originalTotalQuests: 1,
    gameType: 'emotions',
    level: 15,
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

    when(() => mockKidsBloc.state).thenReturn(testLoadedEmotionsState);
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

  Future<void> pumpEmotionsLayout(
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
                body: KidsEmotionsLayout(
                  level: level,
                  title: 'Puppet Theater',
                  primaryColor: Colors.amber,
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

  group('KidsEmotionsLayout - Initial Rendering & Theater Aesthetics', () {
    testWidgets(
      'renders puppet theater stage, red velvet curtains, valance, stage floor, and feeling masks',
      (tester) async {
        await pumpEmotionsLayout(tester);

        expect(
          find.byKey(const Key('kids_emotions_theater_stage_target')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('kids_emotions_replay_audio_button')),
          findsOneWidget,
        );
        expect(find.text('Grandpa pushes you high on the swing and you laugh!'), findsOneWidget);

        expect(find.byKey(const Key('kids_emotions_option_0')), findsOneWidget);
        expect(find.byKey(const Key('kids_emotions_option_1')), findsOneWidget);
        expect(find.byKey(const Key('kids_emotions_option_2')), findsOneWidget);

        expect(find.text('Angry'), findsOneWidget);
        expect(find.text('Happy'), findsOneWidget);
        expect(find.text('Sad'), findsOneWidget);
      },
    );

    testWidgets(
      'renders correct emoji on stage when quest answer status is correct',
      (tester) async {
        final correctState = testLoadedEmotionsState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpEmotionsLayout(tester, state: correctState);

        expect(find.text('😊'), findsWidgets);
      },
    );

    testWidgets(
      'renders cleanly in dark mode without contrast issues',
      (tester) async {
        await pumpEmotionsLayout(tester, themeMode: ThemeMode.dark);

        expect(
          find.byKey(const Key('kids_emotions_theater_stage_target')),
          findsOneWidget,
        );
        expect(find.text('Happy'), findsOneWidget);
      },
    );
  });

  group('KidsEmotionsLayout - Audio Scaffolding', () {
    testWidgets(
      'tapping theater stage replay audio button replays question instruction via TTS',
      (tester) async {
        await pumpEmotionsLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_emotions_replay_audio_button')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak(
            testEmotionsQuest.instruction,
            force: true,
          ),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
      },
    );

    testWidgets(
      'tapping theater stage itself replays question instruction via TTS',
      (tester) async {
        await pumpEmotionsLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_emotions_theater_stage_target')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak(
            testEmotionsQuest.instruction,
            force: true,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping feeling mask speaker button pronounces emotion word via TTS without submitting',
      (tester) async {
        await pumpEmotionsLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_emotions_pronounce_0')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak('Angry', force: true),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );
  });

  group('KidsEmotionsLayout - Dual Interaction (Tap & Drag)', () {
    testWidgets(
      'instant tap-to-answer correct emotion mask dispatches SubmitKidsAnswer(true) and success haptic',
      (tester) async {
        await pumpEmotionsLayout(tester);

        await tester.tap(find.byKey(const Key('kids_emotions_option_1')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(true)),
        ).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      'instant tap-to-answer incorrect emotion mask dispatches SubmitKidsAnswer(false), error haptic, and TTS pronunciation',
      (tester) async {
        await pumpEmotionsLayout(tester);

        await tester.tap(find.byKey(const Key('kids_emotions_option_0')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(false)),
        ).called(1);
        verify(() => mockHapticService.error()).called(1);
        verify(() => mockTTSService.speak('Angry')).called(1);
      },
    );

    testWidgets(
      'drag-and-drop correct emotion mask onto theater stage triggers SubmitKidsAnswer(true)',
      (tester) async {
        await pumpEmotionsLayout(tester);

        final draggableFinder = find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'Happy 😊',
        );
        final dragTargetFinder = find.byKey(
          const Key('kids_emotions_theater_stage_target'),
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
      'drag-and-drop incorrect emotion mask onto theater stage triggers SubmitKidsAnswer(false)',
      (tester) async {
        await pumpEmotionsLayout(tester);

        final draggableFinder = find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'Angry 😠',
        );
        final dragTargetFinder = find.byKey(
          const Key('kids_emotions_theater_stage_target'),
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
        final answeredState = testLoadedEmotionsState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpEmotionsLayout(tester, state: answeredState);

        await tester.tap(
          find.byKey(const Key('kids_emotions_option_1')),
          warnIfMissed: false,
        );
        await tester.pump();

        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );
  });

  group('KidsEmotionsLayout - Small Screen (320dp) & Complex Curriculum Safety', () {
    testWidgets(
      'renders 4 emotion options on compact 320dp width without RenderFlex overflow',
      (tester) async {
        await pumpEmotionsLayout(
          tester,
          state: testLoadedFourOptionsState,
          level: 15,
          width: 320,
          height: 568,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('kids_emotions_theater_stage_target')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('kids_emotions_option_0')), findsOneWidget);
        expect(find.byKey(const Key('kids_emotions_option_1')), findsOneWidget);
        expect(find.byKey(const Key('kids_emotions_option_2')), findsOneWidget);
        expect(find.byKey(const Key('kids_emotions_option_3')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping option on 320dp screen still triggers correct answer flow',
      (tester) async {
        await pumpEmotionsLayout(
          tester,
          state: testLoadedFourOptionsState,
          level: 15,
          width: 320,
          height: 568,
        );

        await tester.tap(find.byKey(const Key('kids_emotions_option_1')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(true)),
        ).called(1);
      },
    );
  });
}
