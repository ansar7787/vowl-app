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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_family_layout.dart';

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

  const testFamilyQuest = KidsQuest(
    id: 'KIDS_FAMILY_L2_Q1',
    gameType: 'family',
    level: 2,
    instruction:
        'Ravi lives with the people who feed him, help him, and love him. What do we call this group of people?',
    question: 'Who cares for you and lives together at home?',
    correctAnswer: 'Family 🏠',
    options: ['Class 🏫', 'Team ⚽', 'Family 🏠'],
    hint: 'Think about the people who care for you at home.',
    emoji: '🏠',
    explanation: 'A family is a group of people who belong together and care for each other.',
    funFact: "The word 'family' comes from the Latin word 'familia'.",
  );

  const testFourOptionsQuest = KidsQuest(
    id: 'KIDS_FAMILY_L20_Q4',
    gameType: 'family',
    level: 20,
    instruction:
        "Your mother's mother tells wonderful stories from long ago. Who is she?",
    question: "Mother's mother storyteller!",
    correctAnswer: 'Grandmother 👵',
    options: ['Grandmother 👵', 'Grandfather 👴', 'Aunt 👩', 'Uncle 👨'],
    hint: 'She is the grandmother of the household.',
    emoji: '👵',
    explanation: 'A grandmother is the mother of one of your parents.',
    funFact: 'Many cultures celebrate Grandparents Day in autumn.',
  );

  const testLoadedFamilyState = KidsLoaded(
    quests: [testFamilyQuest],
    originalTotalQuests: 1,
    gameType: 'family',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedFourOptionsState = KidsLoaded(
    quests: [testFourOptionsQuest],
    originalTotalQuests: 1,
    gameType: 'family',
    level: 20,
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

    when(() => mockKidsBloc.state).thenReturn(testLoadedFamilyState);
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

  Future<void> pumpFamilyLayout(
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
                body: KidsFamilyLayout(
                  level: level,
                  title: 'Living Room Frame',
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

  group('KidsFamilyLayout - Initial Rendering & Living Room Aesthetics', () {
    testWidgets(
      'renders living room framed painting, mantlepiece, and polaroid photo cards',
      (tester) async {
        await pumpFamilyLayout(tester);

        expect(
          find.byKey(const Key('kids_family_frame_target')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('kids_family_replay_audio_button')),
          findsOneWidget,
        );
        expect(find.text('Who cares for you and lives together at home?'), findsOneWidget);

        expect(find.byKey(const Key('kids_family_option_0')), findsOneWidget);
        expect(find.byKey(const Key('kids_family_option_1')), findsOneWidget);
        expect(find.byKey(const Key('kids_family_option_2')), findsOneWidget);

        expect(find.text('Class'), findsOneWidget);
        expect(find.text('Team'), findsOneWidget);
        expect(find.text('Family'), findsOneWidget);
      },
    );

    testWidgets(
      'renders correct family member emoji on framed painting when quest answer status is correct',
      (tester) async {
        final correctState = testLoadedFamilyState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpFamilyLayout(tester, state: correctState);

        expect(find.text('🏠'), findsWidgets);
      },
    );

    testWidgets(
      'renders cleanly in dark mode without contrast issues',
      (tester) async {
        await pumpFamilyLayout(tester, themeMode: ThemeMode.dark);

        expect(
          find.byKey(const Key('kids_family_frame_target')),
          findsOneWidget,
        );
        expect(find.text('Family'), findsOneWidget);
      },
    );
  });

  group('KidsFamilyLayout - Audio Scaffolding', () {
    testWidgets(
      'tapping framed painting replay audio button replays question instruction via TTS',
      (tester) async {
        await pumpFamilyLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_family_replay_audio_button')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak(
            testFamilyQuest.instruction,
            force: true,
          ),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
      },
    );

    testWidgets(
      'tapping framed painting itself replays question instruction via TTS',
      (tester) async {
        await pumpFamilyLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_family_frame_target')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak(
            testFamilyQuest.instruction,
            force: true,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping polaroid photo speaker button pronounces family word via TTS without submitting',
      (tester) async {
        await pumpFamilyLayout(tester);

        await tester.tap(
          find.byKey(const Key('kids_family_pronounce_0')),
        );
        await tester.pump();

        verify(
          () => mockTTSService.speak('Class', force: true),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );
  });

  group('KidsFamilyLayout - Dual Interaction (Tap & Drag)', () {
    testWidgets(
      'instant tap-to-answer correct polaroid photo dispatches SubmitKidsAnswer(true) and success haptic',
      (tester) async {
        await pumpFamilyLayout(tester);

        await tester.tap(find.byKey(const Key('kids_family_option_2')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(true)),
        ).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      'instant tap-to-answer incorrect polaroid photo dispatches SubmitKidsAnswer(false), error haptic, and TTS pronunciation',
      (tester) async {
        await pumpFamilyLayout(tester);

        await tester.tap(find.byKey(const Key('kids_family_option_0')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(false)),
        ).called(1);
        verify(() => mockHapticService.error()).called(1);
        verify(() => mockTTSService.speak('Class')).called(1);
      },
    );

    testWidgets(
      'drag-and-drop correct polaroid photo onto framed painting triggers SubmitKidsAnswer(true)',
      (tester) async {
        await pumpFamilyLayout(tester);

        final draggableFinder = find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'Family 🏠',
        );
        final dragTargetFinder = find.byKey(
          const Key('kids_family_frame_target'),
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
      'drag-and-drop incorrect polaroid photo onto framed painting triggers SubmitKidsAnswer(false)',
      (tester) async {
        await pumpFamilyLayout(tester);

        final draggableFinder = find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'Class 🏫',
        );
        final dragTargetFinder = find.byKey(
          const Key('kids_family_frame_target'),
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
        final answeredState = testLoadedFamilyState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpFamilyLayout(tester, state: answeredState);

        await tester.tap(
          find.byKey(const Key('kids_family_option_2')),
          warnIfMissed: false,
        );
        await tester.pump();

        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );
  });

  group('KidsFamilyLayout - Small Screen (320dp) & Complex Curriculum Safety', () {
    testWidgets(
      'renders 4 family options on compact 320dp width without RenderFlex overflow',
      (tester) async {
        await pumpFamilyLayout(
          tester,
          state: testLoadedFourOptionsState,
          level: 20,
          width: 320,
          height: 568,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('kids_family_frame_target')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('kids_family_option_0')), findsOneWidget);
        expect(find.byKey(const Key('kids_family_option_1')), findsOneWidget);
        expect(find.byKey(const Key('kids_family_option_2')), findsOneWidget);
        expect(find.byKey(const Key('kids_family_option_3')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping option on 320dp screen still triggers correct answer flow',
      (tester) async {
        await pumpFamilyLayout(
          tester,
          state: testLoadedFourOptionsState,
          level: 20,
          width: 320,
          height: 568,
        );

        await tester.tap(find.byKey(const Key('kids_family_option_0')));
        await tester.pump();

        verify(
          () => mockKidsBloc.add(const SubmitKidsAnswer(true)),
        ).called(1);
      },
    );
  });
}

