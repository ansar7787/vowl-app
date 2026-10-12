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
import 'package:vowl/features/kids_zone/kids_routes.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_school_layout.dart';

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

  const testQuest = KidsQuest(
    id: 'KIDS_SCHOOL_L1_Q1',
    gameType: 'school',
    level: 1,
    instruction:
        'Which one do you carry on your back to bring your things to school?',
    question: '?',
    correctAnswer: 'Backpack 🎒',
    options: [
      'Lunchbox 🍱',
      'Backpack 🎒',
      'Pencil Case 👝',
    ],
    hint: 'Look for the one with two straps that go over your shoulders.',
    emoji: '🎒',
    explanation:
        'A backpack holds your books and supplies, and the straps keep your hands free.',
    funFact:
        'Wearing a backpack on both shoulders spreads its weight evenly.',
  );

  const testBatch20Quest = KidsQuest(
    id: 'KIDS_SCHOOL_L191_Q1',
    gameType: 'school',
    level: 191,
    instruction:
        'You were away sick, and you want to write to your teacher. Which message is the clearest and politest?',
    question: '?',
    correctAnswer: "'Dear Ms. Rao, I was unwell. What did I miss?' ✉️",
    options: [
      "'Dear Ms. Rao, I was unwell. What did I miss?' ✉️",
      "'Hi Ms. Rao, I was off. What happened in math?' ✉️",
      "'Dear Ms. Rao, I missed class. Send me everything now.' ✉️",
    ],
    hint: 'Greet, explain, and ask clearly.',
    emoji: '✉️',
    explanation: 'A polite greeting makes your message easy to answer.',
    funFact: 'Specific questions get faster replies.',
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuest],
    originalTotalQuests: 1,
    gameType: 'school',
    level: 1,
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
    when(() => mockKidsBloc.stream).thenAnswer(
      (_) => const Stream<KidsState>.empty(),
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'kid_user_school',
          email: 'student@vowl.app',
          completedLevels: {},
          totalExp: 100,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer(
      (_) => const Stream<AuthState>.empty(),
    );

    when(() => mockTTSService.speak(any(), force: any(named: 'force')))
        .thenAnswer((_) async => true);
    when(() => mockTTSService.isNarrationEnabled()).thenAnswer((_) async => false);
    when(() => mockTTSService.stop()).thenAnswer((_) async {});

    when(() => mockAudioService.playLevelCompleteSFX()).thenAnswer((_) async {});

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.error(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'), tag: any(named: 'tag'))).thenReturn(null);

    when(() => mockLocaleService.tr(any())).thenAnswer((inv) => inv.positionalArguments[0] as String);

    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl.unregister<KidsTTSService>();
    }
    if (di.sl.isRegistered<KidsAudioService>()) {
      di.sl.unregister<KidsAudioService>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }

    di.sl.registerSingleton<KidsTTSService>(mockTTSService);
    di.sl.registerSingleton<KidsAudioService>(mockAudioService);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<KidsTTSService>()) di.sl.unregister<KidsTTSService>();
    if (di.sl.isRegistered<KidsAudioService>()) di.sl.unregister<KidsAudioService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
  });

  Future<void> pumpSchoolLayout(
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
                child: const KidsSchoolLayout(
                  level: 2,
                  title: 'School',
                  primaryColor: Color(0xFF1E3F31),
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

  group('SchoolOptionData.parse RegEx Unit Tests', () {
    test('extracts single-word title and trailing emoji', () {
      final parsed = SchoolOptionData.parse('Backpack 🎒');
      expect(parsed.raw, 'Backpack 🎒');
      expect(parsed.title, 'Backpack');
      expect(parsed.emoji, '🎒');
    });

    test('extracts multi-word title and trailing emoji', () {
      final parsed = SchoolOptionData.parse('Pencil Case 👝');
      expect(parsed.title, 'Pencil Case');
      expect(parsed.emoji, '👝');
    });

    test('handles complex multi-byte ZWJ teacher emoji', () {
      final parsed = SchoolOptionData.parse('Teacher 🧑‍🏫');
      expect(parsed.title, 'Teacher');
      expect(parsed.emoji, '🧑‍🏫');
    });

    test('extracts long quoted message sentence and trailing emoji', () {
      final parsed = SchoolOptionData.parse(
        "'Dear Ms. Rao, I was unwell. What did I miss?' ✉️",
      );
      expect(
        parsed.title,
        "'Dear Ms. Rao, I was unwell. What did I miss?'",
      );
      expect(parsed.emoji, '✉️');
    });

    test('handles text without emoji gracefully without stripping words', () {
      final parsed = SchoolOptionData.parse('Whiteboard Marker');
      expect(parsed.title, 'Whiteboard Marker');
      expect(parsed.emoji, isNull);
    });

    test('handles empty and whitespace strings gracefully', () {
      final empty = SchoolOptionData.parse('');
      expect(empty.title, isEmpty);
      expect(empty.emoji, isNull);

      final whitespace = SchoolOptionData.parse('   ');
      expect(whitespace.title, '   ');
      expect(whitespace.emoji, isNull);
    });
  });

  group('KidsSchoolLayout Production Tests', () {
    testWidgets(
      'renders Classroom Chalkboard, Riddle Clue, prompt, and all options fully with no truncation',
      (tester) async {
        await pumpSchoolLayout(tester);

        // 1. Header & Classroom Clue title
        expect(find.text('Classroom Clue'), findsOneWidget);
        expect(find.text('Listen'), findsOneWidget);

        // 2. Riddle Clue text (displayed on blackboard and mascot speech bubble)
        expect(
          find.text(
            'Which one do you carry on your back to bring your things to school?',
          ),
          findsWidgets,
        );

        // 3. Instruction prompt
        expect(
          find.text('Tap an answer or drag it to the board'),
          findsOneWidget,
        );

        // 4. All options visible
        expect(find.text('Lunchbox'), findsOneWidget);
        expect(find.text('Backpack'), findsOneWidget);
        expect(find.text('Pencil Case'), findsOneWidget);

        // 5. Drag target exists
        expect(find.byType(DragTarget<String>), findsOneWidget);
      },
    );

    testWidgets(
      'unanswered state does not spoil answer emoji silhouette',
      (tester) async {
        await pumpSchoolLayout(tester);

        // The answer emoji "🎒" must not be displayed inside the chalkboard target during unanswered state
        // It should only appear on the Backpack option card
        final emojiFinders = find.text('🎒');
        expect(emojiFinders, findsOneWidget); // Only on the option card, not inside chalkboard!
      },
    );

    testWidgets(
      'correct state reveals triumphant celebration with answer emoji and well done banner',
      (tester) async {
        const correctState = KidsLoaded(
          quests: [testQuest],
          originalTotalQuests: 1,
          gameType: 'school',
          level: 1,
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.correct,
        );

        await pumpSchoolLayout(tester, state: correctState);

        expect(find.text('Well done!'), findsOneWidget);
        // Now the emoji 🎒 is displayed inside the solved chalkboard area
        expect(find.text('🎒'), findsWidgets);
      },
    );

    testWidgets(
      'tap-to-answer submits correct answer to KidsBloc and plays pronunciation',
      (tester) async {
        await pumpSchoolLayout(tester);

        await tester.tap(find.text('Backpack'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
        verify(() => mockTTSService.speak('Backpack', force: true)).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      'tap-to-answer submits incorrect answer with error haptic and audio',
      (tester) async {
        await pumpSchoolLayout(tester);

        await tester.tap(find.text('Lunchbox'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
        verify(() => mockTTSService.speak('Lunchbox', force: true)).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );

    testWidgets(
      'tapping clue Listen button replays question instruction via TTS',
      (tester) async {
        await pumpSchoolLayout(tester);

        await tester.tap(find.text('Listen'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(
          () => mockTTSService.speak(
            'Which one do you carry on your back to bring your things to school?',
            force: true,
          ),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
      },
    );

    testWidgets(
      'option audio speaker button plays option pronunciation without submitting answer',
      (tester) async {
        await pumpSchoolLayout(tester);

        final hearButton = find.bySemanticsLabel('Pronounce Backpack');
        expect(hearButton, findsOneWidget);

        await tester.tap(hearButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockTTSService.speak('Backpack', force: true)).called(1);
        verify(() => mockHapticService.selection()).called(1);
        verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
      },
    );

    testWidgets(
      'drag-and-drop correct option onto chalkboard target submits answer',
      (tester) async {
        await pumpSchoolLayout(tester);

        final draggableFinder = find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'Backpack 🎒',
        );
        expect(draggableFinder, findsOneWidget);

        final targetFinder = find.byType(DragTarget<String>);
        expect(targetFinder, findsOneWidget);

        final dragLocation = tester.getCenter(targetFinder);
        final gesture = await tester.startGesture(tester.getCenter(draggableFinder));
        await tester.pump(const Duration(milliseconds: 100));

        await gesture.moveTo(dragLocation);
        await tester.pump(const Duration(milliseconds: 100));

        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      },
    );

    testWidgets(
      'renders wide message cards for sentence-length options (Batch 20 scenario)',
      (tester) async {
        const batch20LoadedState = KidsLoaded(
          quests: [testBatch20Quest],
          originalTotalQuests: 1,
          gameType: 'school',
          level: 191,
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
        );

        await pumpSchoolLayout(tester, state: batch20LoadedState);

        expect(
          find.text("'Dear Ms. Rao, I was unwell. What did I miss?'"),
          findsOneWidget,
        );
        expect(
          find.text("'Hi Ms. Rao, I was off. What happened in math?'"),
          findsOneWidget,
        );
        expect(
          find.text("'Dear Ms. Rao, I missed class. Send me everything now.'"),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'dims an incorrect distractor when hintUsed is active',
      (tester) async {
        const hintState = KidsLoaded(
          quests: [testQuest],
          originalTotalQuests: 1,
          gameType: 'school',
          level: 1,
          currentIndex: 0,
          livesRemaining: 3,
          hintUsed: true,
          answerStatus: AnswerStatus.unanswered,
        );

        await pumpSchoolLayout(tester, state: hintState);

        // One distractor should be wrapped in Opacity(opacity: 0.35)
        final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
        final hasDimmed = opacityWidgets.any((op) => op.opacity == 0.35);
        expect(hasDimmed, isTrue);
      },
    );

    testWidgets(
      'renders cleanly on compact 360x640 phone without overflow',
      (tester) async {
        await pumpSchoolLayout(tester, width: 360, height: 640);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly on large 430x932 phone without overflow',
      (tester) async {
        await pumpSchoolLayout(tester, width: 430, height: 932);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders cleanly on ultra-narrow 320x568 phone without overflow',
      (tester) async {
        await pumpSchoolLayout(tester, width: 320, height: 568);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'already answered state disables re-submitting upon taps',
      (tester) async {
        const answeredState = KidsLoaded(
          quests: [testQuest],
          originalTotalQuests: 1,
          gameType: 'school',
          level: 1,
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.correct,
        );

        await pumpSchoolLayout(tester, state: answeredState);

        // In answered state, options are not wrapped in Draggable
        expect(find.byType(Draggable<String>), findsNothing);

        final backpackFinders = find.text('Backpack');
        expect(backpackFinders, findsWidgets);
        await tester.tap(backpackFinders.last, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
      },
    );

    testWidgets(
      'interaction triggers structured debug logs via AppLogger with KidsSchoolLayout tag',
      (tester) async {
        await pumpSchoolLayout(tester);

        // Verify sync logging occurred
        verify(
          () => mockLogger.debug(
            any(that: contains('Syncing state with quest')),
            tag: 'KidsSchoolLayout',
          ),
        ).called(greaterThanOrEqualTo(1));

        // Tap Backpack and verify submission log
        await tester.tap(find.text('Backpack'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(
          () => mockLogger.debug(
            any(that: contains('Submitting option')),
            tag: 'KidsSchoolLayout',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'empty options quest logs warning via AppLogger with KidsSchoolLayout tag',
      (tester) async {
        const emptyOptionsQuest = KidsQuest(
          id: 'KIDS_SCHOOL_EMPTY_OPTS',
          gameType: 'school',
          level: 1,
          instruction: 'Empty options test',
          question: '?',
          correctAnswer: 'None',
          options: [],
        );

        const emptyState = KidsLoaded(
          quests: [emptyOptionsQuest],
          originalTotalQuests: 1,
          gameType: 'school',
          level: 1,
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
        );

        await pumpSchoolLayout(tester, state: emptyState);

        verify(
          () => mockLogger.warning(
            any(that: contains('empty options list')),
            tag: 'KidsSchoolLayout',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'renders 4 options in 2x2 grid cleanly without overflow',
      (tester) async {
        const fourOptionsQuest = KidsQuest(
          id: 'KIDS_SCHOOL_L1_4OPTS',
          gameType: 'school',
          level: 1,
          instruction: 'Which tool do you use to measure length?',
          question: '?',
          correctAnswer: 'Ruler 📏',
          options: [
            'Ruler 📏',
            'Eraser 🧼',
            'Pencil ✏️',
            'Book 📖',
          ],
          emoji: '📏',
        );

        const fourOptsState = KidsLoaded(
          quests: [fourOptionsQuest],
          originalTotalQuests: 1,
          gameType: 'school',
          level: 1,
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
        );

        await pumpSchoolLayout(tester, state: fourOptsState);

        expect(find.text('Ruler'), findsOneWidget);
        expect(find.text('Eraser'), findsOneWidget);
        expect(find.text('Pencil'), findsOneWidget);
        expect(find.text('Book'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('School Game Service Integration Tests', () {
    test(
      'StoryService kidsScripts defines all school milestone beats up to level 100 and beyond without buzzwords',
      () {
        final schoolBeats = StoryServiceImpl.kidsScripts['school'];
        expect(schoolBeats, isNotNull);
        expect(schoolBeats!.length, equals(6));

        // Beat 0: Level 1 introduction
        expect(schoolBeats[0], contains('backpacks'));
        expect(schoolBeats[0], contains('classroom'));

        // Beat 1: Level 10
        expect(schoolBeats[1], contains('first 10 levels'));

        // Beat 2: Level 20
        expect(schoolBeats[2], contains('Twenty levels complete'));

        // Beat 3: Level 50
        expect(schoolBeats[3], contains('Fifty levels done'));

        // Beat 4: Level 100
        expect(schoolBeats[4], contains('One hundred levels completed'));

        // Beat 5: Level 200
        expect(schoolBeats[5], contains('Two hundred levels completed'));

        // Never uses buzzwords or robotic tropes
        for (final beat in schoolBeats) {
          expect(beat.contains('superpower'), isFalse);
          expect(beat.contains("Teacher's Pet"), isFalse);
          expect(beat.contains('Fun School'), isFalse);
        }
      },
    );

    testWidgets(
      'GameInstructionService returns authentic School briefing matching game mechanics',
      (tester) async {
        late BuildContext capturedContext;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final briefing = GameInstructionService.getBriefing(
          capturedContext,
          null,
          'school',
          level: 1,
        );

        expect(briefing.title, 'School Days');
        expect(briefing.icon, Icons.school_rounded);
        expect(briefing.actionText, 'Go to School');
        expect(briefing.objective, contains('classroom clue'));
        expect(briefing.objective, contains('desk'));
        expect(briefing.rules.length, equals(3));
        expect(briefing.rules[0], contains('chalkboard'));
        expect(briefing.rules[1], contains('desk'));
        expect(briefing.rules[2], contains('speaker'));
        expect(briefing.tip, contains('Listen'));
      },
    );

    test(
      'KidsRoutes defines canonical School title and route',
      () {
        expect(KidsRoutes.getKidsGameTitle('school'), 'School');
        expect(KidsRoutes.kidsSchoolRoute, '/kids-school');
      },
    );
  });
}
