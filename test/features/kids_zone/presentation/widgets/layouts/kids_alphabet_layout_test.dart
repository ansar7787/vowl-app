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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_alphabet_layout.dart';

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
    id: 'KIDS_ALPHABET_L2_Q1',
    gameType: 'alphabet',
    level: 2,
    instruction: 'Can you spot the big letter N?',
    question: 'Spot the letter N',
    correctAnswer: 'N',
    options: ['C', 'U', 'N'],
    hint: 'Look for two tall lines joined by a slanted line.',
    emoji: '📓',
    wordExample: 'Notebook',
    wordEmoji: '📓',
    phonetic: 'en',
    explanation:
        'That is N. Its name is en, and you can see it at the start of Notebook.',
    funFact:
        'When n and g come together, as in ring and song, they make one sound.',
  );

  const testQuestLongOptions = KidsQuest(
    id: 'KIDS_ALPHABET_L191_Q2',
    gameType: 'alphabet',
    level: 191,
    instruction:
        'Which word starts with a letter that comes after G in the alphabet?',
    question: 'Find the word that comes after G',
    correctAnswer: 'UFO',
    options: ['UFO', 'Castle', 'Dinosaur'],
    hint: 'Check Castle first: it begins with C. Is that letter after G?',
    emoji: '🛸',
    wordExample: 'UFO',
    wordEmoji: '🛸',
    phonetic: 'you',
    explanation: 'UFO begins with U, which comes after G.',
    funFact: 'Capital U and V look alike, but U has a curve at the bottom.',
  );

  const testLoadedStateShort = KidsLoaded(
    quests: [testQuestShortOptions],
    originalTotalQuests: 1,
    gameType: 'alphabet',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLoadedStateLong = KidsLoaded(
    quests: [testQuestLongOptions],
    originalTotalQuests: 1,
    gameType: 'alphabet',
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

  Future<void> pumpAlphabetLayout(
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
                body: KidsAlphabetLayout(
                  level: 2,
                  title: 'Alphabet',
                  primaryColor: Color(0xFFF59E0B),
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

  group('KidsAlphabetLayout - Component Rendering', () {
    testWidgets('renders blackboard with question, instruction, and header',
        (tester) async {
      await pumpAlphabetLayout(tester);

      expect(find.text('ALPHABET BOARD'), findsOneWidget);
      expect(find.text('Spot the letter N'), findsOneWidget);
      expect(find.byKey(const ValueKey('alphabet_audio_replay_btn')), findsOneWidget);
    });

    testWidgets('renders 3 wooden alphabet blocks for short options',
        (tester) async {
      await pumpAlphabetLayout(tester);

      expect(find.text('C'), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
    });

    testWidgets('renders wide wooden banners when options are words',
        (tester) async {
      await pumpAlphabetLayout(tester, state: testLoadedStateLong);

      expect(find.text('UFO'), findsOneWidget);
      expect(find.text('Castle'), findsOneWidget);
      expect(find.text('Dinosaur'), findsOneWidget);
    });
  });

  group('KidsAlphabetLayout - Interaction & Submission', () {
    testWidgets(
        'tap on correct wooden block submits SubmitKidsAnswer(true) and speaks answer',
        (tester) async {
      await pumpAlphabetLayout(tester);

      final correctOption = find.text('N');
      expect(correctOption, findsOneWidget);
      await tester.ensureVisible(correctOption);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockTTSService.speak('N', force: true)).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets(
        'tap on incorrect wooden block submits SubmitKidsAnswer(false) and triggers error haptic',
        (tester) async {
      await pumpAlphabetLayout(tester);

      final wrongOption = find.text('C');
      expect(wrongOption, findsOneWidget);
      await tester.ensureVisible(wrongOption);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
      verify(() => mockTTSService.speak('C', force: true)).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('tapping speaker icon on block pronounces letter without submitting',
        (tester) async {
      await pumpAlphabetLayout(tester);

      final hearButton = find.byKey(const ValueKey('speaker_block_N'));
      expect(hearButton, findsOneWidget);
      await tester.ensureVisible(hearButton);

      await tester.tap(hearButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('N', force: true)).called(1);
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('tapping audio replay button in chalkboard invokes TTS',
        (tester) async {
      await pumpAlphabetLayout(tester);

      final replayButton =
          find.byKey(const ValueKey('alphabet_audio_replay_btn'));
      expect(replayButton, findsOneWidget);
      await tester.ensureVisible(replayButton);

      await tester.tap(replayButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak(any(), force: true)).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('drag-and-drop block to chalkboard submits answer',
        (tester) async {
      await pumpAlphabetLayout(tester);

      final nFinder = find.text('N');
      final chalkboardFinder = find.byType(DragTarget<String>);

      expect(nFinder, findsOneWidget);
      expect(chalkboardFinder, findsOneWidget);
      await tester.ensureVisible(nFinder);

      final dragLocation = tester.getCenter(chalkboardFinder);
      final gesture = await tester.startGesture(tester.getCenter(nFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });
  });

  group('KidsAlphabetLayout - Feedback & Lifeline Scaffolding', () {
    testWidgets(
        'displays celebratory reveal with emoji and example word when answered correctly',
        (tester) async {
      const correctState = KidsLoaded(
        quests: [testQuestShortOptions],
        originalTotalQuests: 1,
        gameType: 'alphabet',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpAlphabetLayout(tester, state: correctState);

      expect(find.text('📓'), findsWidgets);
      expect(find.text('N'), findsWidgets);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      expect(find.text('/en/'), findsOneWidget);
    });

    testWidgets('hint lifeline dims distractor block when hintUsed is true',
        (tester) async {
      const hintState = KidsLoaded(
        quests: [testQuestShortOptions],
        originalTotalQuests: 1,
        gameType: 'alphabet',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await pumpAlphabetLayout(tester, state: hintState);

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      final hasDimmedDistractor = opacities.any((o) => o.opacity == 0.35);
      expect(hasDimmedDistractor, isTrue);
    });
  });

  group('KidsAlphabetLayout - Responsive Layout Safety', () {
    testWidgets('renders cleanly without overflow on narrow 320dp screen',
        (tester) async {
      await pumpAlphabetLayout(tester, width: 320, height: 600);

      expect(find.text('ALPHABET BOARD'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow on tablet 600dp screen',
        (tester) async {
      await pumpAlphabetLayout(tester, width: 600, height: 960);

      expect(find.text('ALPHABET BOARD'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

