import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/pages/read_and_answer_screen.dart';

class MockReadingBloc extends MockBloc<ReadingEvent, ReadingState>
    implements ReadingBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class FakeReadingEvent extends Fake implements ReadingEvent {}

class FakeReadingState extends Fake implements ReadingState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReadingBloc mockReadingBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockLogger;

  setUpAll(() {
    registerFallbackValue(FakeReadingEvent());
    registerFallbackValue(FakeReadingState());
    registerFallbackValue(const SubmitAnswer(true));
  });

  const testDirectQuest = ReadingQuest(
    id: 'RDG_READANDANSWER_L1_Q1',
    instruction: 'Read the passage and select the correct answer.',
    difficulty: 1,
    subtype: GameSubtype.readAndAnswer,
    passage:
        '[Library Notice] The library is open from 9 a.m. to 6 p.m. on weekdays. On Saturday it closes at noon. It is closed on Sunday.',
    question: 'At what time does the library close on Saturday?',
    options: [
      'At noon',
      'At 6 p.m.',
      'At 9 a.m.',
      'At 5 p.m.',
    ],
    correctAnswer: 'At noon',
    correctAnswerIndex: 0,
    hint: 'Read the second sentence closely.',
    explanation: 'The library closes at noon on Saturday.',
    passageWordCount: 25,
    evidenceLine: '', // Direct tap-to-answer without secondary evidence phase
  );

  const testEvidenceQuest = ReadingQuest(
    id: 'RDG_READANDANSWER_L1_Q2',
    instruction: 'Read the passage and select the correct answer.',
    difficulty: 1,
    subtype: GameSubtype.readAndAnswer,
    passage:
        '[Library Notice] The library is open from 9 a.m. to 6 p.m. on weekdays. On Saturday it closes at noon. It is closed on Sunday.',
    question: 'Which day is the library closed?',
    options: [
      'Saturday',
      'Friday',
      'Sunday',
      'Monday',
    ],
    correctAnswer: 'Sunday',
    correctAnswerIndex: 2,
    hint: 'The last sentence names the closed day.',
    explanation: 'The library is closed on Sunday.',
    passageWordCount: 25,
    evidenceLine: 'It is closed on Sunday',
  );

  const testLongStoryQuest = ReadingQuest(
    id: 'RDG_READANDANSWER_L1_Q_LONG',
    instruction:
        'Read the lengthy historical passage carefully and analyze the main conclusion presented.',
    difficulty: 3,
    subtype: GameSubtype.readAndAnswer,
    passage:
        '[Ancient Maritime Expeditions] During the third epoch of the coastal dynasties, intrepid navigators ventured across uncharted archipelagos without modern magnetic compasses, relying solely on celestial navigation and avian migratory corridors. Their multi-tiered galleons were reinforced with waterproof cedar resin and double-layered hemp ropes to withstand torrential monsoon conditions encountered in the outer oceanic trenches.',
    question:
        'What primary navigation method guided these ancient expeditions across uncharted archipelagos?',
    options: [
      'Celestial navigation and avian migratory corridors',
      'Advanced magnetic compasses and automated gyroscopes',
      'Subsea acoustic sonar transponders',
      'Steam engine propelled navigational beacons',
    ],
    correctAnswer: 'Celestial navigation and avian migratory corridors',
    correctAnswerIndex: 0,
    passageWordCount: 65,
    evidenceLine:
        'relying solely on celestial navigation and avian migratory corridors',
  );

  const testLoadedState = ReadingLoaded(
    quests: [testDirectQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockReadingBloc = MockReadingBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockReadingBloc.state).thenReturn(testLoadedState);
    when(() => mockReadingBloc.stream)
        .thenAnswer((_) => const Stream<ReadingState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'reader@vowl.app',
          displayName: 'Reader',
          vowlMascot: 'vowl_prime',
          completedLevels: {},
          totalExp: 120,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(
      () => mockSoundService.playTts(
        any(),
        speed: any(named: 'speed'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
        isKids: any(named: 'isKids'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(any())).thenAnswer(
      (inv) => inv.positionalArguments.first as String,
    );

    when(() => mockLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(
      () => mockLogger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
        tag: any(named: 'tag'),
      ),
    ).thenReturn(null);

    // Register mocks in DI
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
  });

  Future<void> pumpReadAndAnswer(
    WidgetTester tester, {
    ReadingState? state,
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
      when(() => mockReadingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ReadingBloc>.value(value: mockReadingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: ReadAndAnswerScreen(level: 2),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ReadAndAnswerScreen - Production Layout & Mechanics Tests', () {
    testWidgets('1. Initial rendering of question, passage, and buoy options',
        (tester) async {
      await pumpReadAndAnswer(tester);

      // Verify instruction / topic badge
      expect(find.text('LIBRARY NOTICE'), findsOneWidget);

      // Verify Question
      expect(
        find.text('At what time does the library close on Saturday?'),
        findsOneWidget,
      );

      // Verify Anchor Point & Floating Passage
      expect(
        find.byKey(const ValueKey('read_and_answer_anchor_point')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('read_and_answer_floating_passage')),
        findsOneWidget,
      );

      // Verify Options
      expect(find.text('At noon'), findsOneWidget);
      expect(find.text('At 6 p.m.'), findsOneWidget);
      expect(find.text('At 9 a.m.'), findsOneWidget);
      expect(find.text('At 5 p.m.'), findsOneWidget);

      // Verify audio replay buttons exist
      expect(
        find.byKey(const ValueKey('read_and_answer_tts_question_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('read_and_answer_tts_passage_button')),
        findsOneWidget,
      );
    });

    testWidgets('2. Audio replay button triggers TTS speech', (tester) async {
      await pumpReadAndAnswer(tester);

      // Tap question TTS button
      final questionTtsBtn =
          find.byKey(const ValueKey('read_and_answer_tts_question_button'));
      expect(questionTtsBtn, findsOneWidget);
      await tester.tap(questionTtsBtn);
      await tester.pump(const Duration(milliseconds: 50));

      verify(
        () => mockSoundService.playTts(
          'At what time does the library close on Saturday?',
        ),
      ).called(1);

      // Tap passage TTS button
      final passageTtsBtn =
          find.byKey(const ValueKey('read_and_answer_tts_passage_button'));
      expect(passageTtsBtn, findsOneWidget);
      await tester.tap(passageTtsBtn);
      await tester.pump(const Duration(milliseconds: 50));

      verify(
        () => mockSoundService.playTts(
          any(that: contains('The library is open from 9 a.m.')),
        ),
      ).called(1);
    });

    testWidgets(
        '3. Tap-to-answer correct path dispatches SubmitAnswer(true) and haptics',
        (tester) async {
      await pumpReadAndAnswer(tester);

      final correctOptionTap =
          find.byKey(const ValueKey('read_and_answer_option_tap_0'));
      expect(correctOptionTap, findsOneWidget);

      await tester.tap(correctOptionTap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify selection haptic and correct submission
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets(
        '4. Tap-to-answer incorrect path dispatches SubmitAnswer(false), wrong SFX, and error haptics',
        (tester) async {
      await pumpReadAndAnswer(tester);

      final wrongOptionTap =
          find.byKey(const ValueKey('read_and_answer_option_tap_1'));
      expect(wrongOptionTap, findsOneWidget);

      await tester.tap(wrongOptionTap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets(
        '5. Drag-and-drop interaction accepts option drop onto anchor point',
        (tester) async {
      await pumpReadAndAnswer(tester);

      final optionDraggable =
          find.byKey(const ValueKey('read_and_answer_option_0'));
      final anchorTarget =
          find.byKey(const ValueKey('read_and_answer_drag_target'));

      expect(optionDraggable, findsOneWidget);
      expect(anchorTarget, findsOneWidget);

      // Drag option 0 upwards onto the anchor point target
      final gesture = await tester.startGesture(
        tester.getCenter(optionDraggable),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.moveTo(tester.getCenter(anchorTarget));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Dropping correct answer on anchor target triggers answer flow
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('6. Evidence phase triggers when evidenceLine is present',
        (tester) async {
      final evidenceState = const ReadingLoaded(
        quests: [testEvidenceQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpReadAndAnswer(tester, state: evidenceState);

      // Option 2 ('Sunday') is correct for testEvidenceQuest
      final option2Tap =
          find.byKey(const ValueKey('read_and_answer_option_tap_2'));
      await tester.ensureVisible(option2Tap);
      await tester.tap(option2Tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Selection haptic plays and evidence step is activated
      verify(() => mockHapticService.selection()).called(1);

      // Verify instruction to tap evidence words appears
      expect(
        find.text('Tap the words that prove your answer'),
        findsOneWidget,
      );
    });

    testWidgets(
        '7. Long content / story problem adaptability without truncation',
        (tester) async {
      final longContentState = const ReadingLoaded(
        quests: [testLongStoryQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpReadAndAnswer(tester, state: longContentState);

      expect(find.text('ANCIENT MARITIME EXPEDITIONS'), findsOneWidget);
      expect(
        find.textContaining('During the third epoch of the coastal dynasties'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Celestial navigation and avian migratory corridors',
        ),
        findsOneWidget,
      );

      // Scroll smoothly down the CustomScrollView to verify layout
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -300),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Small screen (320dp width) zero-overflow layout safety',
        (tester) async {
      await pumpReadAndAnswer(
        tester,
        width: 320,
        height: 568,
      );

      // Verify no RenderFlex overflow occurs on ultra-compact 320dp screen
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('read_and_answer_anchor_point')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('read_and_answer_floating_passage')),
        findsOneWidget,
      );
    });
  });
}
