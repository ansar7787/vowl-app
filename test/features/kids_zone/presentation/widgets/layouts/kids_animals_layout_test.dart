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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_animals_layout.dart';

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
    id: 'KIDS_ANIMALS_L2_Q1',
    gameType: 'animals',
    level: 2,
    instruction:
        'A farmer trims a thick, fluffy coat off this animal so it can be spun into yarn. Which animal is it?',
    question: 'Sheep',
    correctAnswer: '🐑',
    options: ['🐶', '🐷', '🐑'],
    hint: 'Think about what a warm hat or scarf is knitted from.',
    explanation: 'Sheep grow thick woolly coats.',
    animalSound: 'Baa',
    funFact:
        'A sheep pupils are shaped like horizontal rectangles, which helps it see almost all the way around.',
  );

  const testQuestLong = KidsQuest(
    id: 'KIDS_ANIMALS_L191_Q1',
    gameType: 'animals',
    level: 191,
    instruction:
        'Wolves return to a valley. Fewer deer nibble the young willow trees, and the willows grow back along the stream. Which animal, which needs willows for food and dam-building, can now return?',
    question: 'Beaver',
    correctAnswer: '🦫',
    options: ['🦬', '🦆', '🦫'],
    hint:
        'Follow the chain from wolves to deer to trees to the animal that uses the trees.',
    explanation:
        'Wolves reduce deer browsing. That lets willows recover, which gives beavers food.',
    animalSound: 'Tail Slap',
    funFact: 'After wolves returned to Yellowstone, beaver colonies there increased.',
  );

  const testLoadedStateShort = KidsLoaded(
    quests: [testQuestShort],
    originalTotalQuests: 1,
    gameType: 'animals',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedStateLong = KidsLoaded(
    quests: [testQuestLong],
    originalTotalQuests: 1,
    gameType: 'animals',
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

  Future<void> pumpAnimalsLayout(
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
                body: KidsAnimalsLayout(
                  level: 2,
                  title: 'Animals',
                  primaryColor: Color(0xFF166534),
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

  group('KidsAnimalsLayout - Component Rendering', () {
    testWidgets('renders safari binoculars with riddle and audio button',
        (tester) async {
      await pumpAnimalsLayout(tester);

      expect(find.text('SAFARI BINOCULARS'), findsOneWidget);
      expect(find.text('SAFARI CLUE'), findsOneWidget);
      expect(
        find.textContaining('A farmer trims a thick, fluffy coat'),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('animals_audio_replay_btn')),
        findsOneWidget,
      );
    });

    testWidgets('renders 3 wooden animal signpost options', (tester) async {
      await pumpAnimalsLayout(tester);

      expect(find.text('🐶'), findsOneWidget);
      expect(find.text('🐷'), findsOneWidget);
      expect(find.text('🐑'), findsOneWidget);
    });

    testWidgets('renders correctly when questions have long ecosystem stories',
        (tester) async {
      await pumpAnimalsLayout(tester, state: testLoadedStateLong);

      expect(find.text('🦬'), findsOneWidget);
      expect(find.text('🦆'), findsOneWidget);
      expect(find.text('🦫'), findsOneWidget);
      expect(
        find.textContaining('Wolves return to a valley'),
        findsWidgets,
      );
    });
  });

  group('KidsAnimalsLayout - Interaction & Submission', () {
    testWidgets(
        'tap on correct animal signpost submits SubmitKidsAnswer(true) and speaks sound',
        (tester) async {
      await pumpAnimalsLayout(tester);

      final correctOption = find.text('🐑');
      expect(correctOption, findsOneWidget);
      await tester.ensureVisible(correctOption);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockTTSService.speak('Baa', force: true)).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets(
        'tap on incorrect animal signpost submits SubmitKidsAnswer(false) and triggers error haptic',
        (tester) async {
      await pumpAnimalsLayout(tester);

      final wrongOption = find.text('🐶');
      expect(wrongOption, findsOneWidget);
      await tester.ensureVisible(wrongOption);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
      verify(() => mockTTSService.speak('🐶', force: true)).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('tapping speaker icon on signpost pronounces animal sound without submitting',
        (tester) async {
      await pumpAnimalsLayout(tester);

      final hearButton = find.byKey(const ValueKey('speaker_animal_🐑'));
      expect(hearButton, findsOneWidget);
      await tester.ensureVisible(hearButton);

      await tester.tap(hearButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak(any(), force: true)).called(1);
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('tapping audio replay button in binoculars invokes TTS',
        (tester) async {
      await pumpAnimalsLayout(tester);

      final replayButton =
          find.byKey(const ValueKey('animals_audio_replay_btn'));
      expect(replayButton, findsOneWidget);
      await tester.ensureVisible(replayButton);

      await tester.tap(replayButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak(any(), force: true)).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('drag-and-drop animal to binoculars submits answer',
        (tester) async {
      await pumpAnimalsLayout(tester);

      final sheepFinder = find.text('🐑');
      final binocularsFinder = find.byType(DragTarget<String>);

      expect(sheepFinder, findsOneWidget);
      expect(binocularsFinder, findsOneWidget);
      await tester.ensureVisible(sheepFinder);

      final dragLocation = tester.getCenter(binocularsFinder);
      final gesture = await tester.startGesture(tester.getCenter(sheepFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });
  });

  group('KidsAnimalsLayout - Feedback & Lifeline Scaffolding', () {
    testWidgets(
        'displays celebratory reveal with animal name and sound when answered correctly',
        (tester) async {
      const correctState = KidsLoaded(
        quests: [testQuestShort],
        originalTotalQuests: 1,
        gameType: 'animals',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpAnimalsLayout(tester, state: correctState);

      expect(find.text('Sheep'), findsWidgets);
      expect(find.text('Sound: "Baa"'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
    });

    testWidgets('hint lifeline dims distractor signpost when hintUsed is true',
        (tester) async {
      const hintState = KidsLoaded(
        quests: [testQuestShort],
        originalTotalQuests: 1,
        gameType: 'animals',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await pumpAnimalsLayout(tester, state: hintState);

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      final hasDimmedDistractor = opacities.any((o) => o.opacity == 0.35);
      expect(hasDimmedDistractor, isTrue);
    });
  });

  group('KidsAnimalsLayout - Responsive Layout Safety', () {
    testWidgets('renders cleanly without overflow on narrow 320dp screen',
        (tester) async {
      await pumpAnimalsLayout(tester, width: 320, height: 600);

      expect(find.text('SAFARI BINOCULARS'), findsOneWidget);
      expect(find.text('🐑'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow on tablet 600dp screen',
        (tester) async {
      await pumpAnimalsLayout(tester, width: 600, height: 960);

      expect(find.text('SAFARI BINOCULARS'), findsOneWidget);
      expect(find.text('🐑'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

