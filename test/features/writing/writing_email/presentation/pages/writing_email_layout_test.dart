import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/writing_email/presentation/pages/writing_email_screen.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_data_stream.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_hex_slot.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_instruction.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_prompt_card.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';

class MockWritingBloc extends Mock implements WritingBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockEconomyBloc extends Mock implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}
class MockTtsService extends Mock implements TtsService {}
class MockLocaleService extends Mock implements LocaleService {}
class MockAppLogger extends Mock implements AppLogger {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAdService extends Mock implements AdService {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeWritingEvent extends Fake implements WritingEvent {}
class FakeWritingState extends Fake implements WritingState {}
class FakeEconomyEvent extends Fake implements EconomyEvent {}
class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  late MockWritingBloc mockWritingBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<WritingState> writingStreamController;

  const sampleQuest1 = WritingQuest(
    id: 'quest_we_1',
    instruction: 'Arrange the email into the correct order.',
    formalityLevel: 'formal',
    difficulty: 2,
    subtype: GameSubtype.writingEmail,
    prompt: 'Write a formal email to request a meeting with Professor Vance regarding the research fellowship.',
    options: [
      'Meeting Request: Research Fellowship Discussion',
      'Dear Professor Vance,',
      'I am writing to respectfully request a brief appointment next week to discuss the research fellowship.',
      'Sincerely,\nElena Rostova',
    ],
    correctOrder: [0, 1, 2, 3],
    hint: 'Start with the subject line, follow with the formal salutation, body paragraph, and closing sign-off.',
    explanation: 'Standard professional correspondence adheres to a four-part structure: Subject, Salutation, Body, and Valediction.',
  );

  const sampleQuest2 = WritingQuest(
    id: 'quest_we_2',
    instruction: 'Arrange the informal email sequence.',
    formalityLevel: 'informal',
    difficulty: 2,
    subtype: GameSubtype.writingEmail,
    prompt: 'Send a quick informal note to Alex about weekend hiking plans.',
    options: [
      'Weekend Hiking Trail',
      'Hey Alex,',
      'Are we still on for the trail this Saturday morning? Let me know if 8 AM works.',
      'Cheers,\nLiam',
    ],
    correctOrder: [0, 1, 2, 3],
    hint: 'Start with the hiking subject.',
    explanation: 'Informal email sequencing.',
  );

  const sampleQuest3Options = WritingQuest(
    id: 'quest_we_3',
    instruction: 'Arrange the team announcement.',
    formalityLevel: null,
    difficulty: 2,
    subtype: GameSubtype.writingEmail,
    prompt: 'Organize the party announcement.',
    options: [
      'Announcement: Office Holiday Party',
      'Hi Team,\nThe annual holiday party will take place next Friday at 6 PM.',
      'Best regards,\nOperations',
    ],
    correctOrder: [0, 1, 2],
  );

  const testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.writingEmail,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(FakeWritingEvent());
    registerFallbackValue(FakeWritingState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const WritingHintUsed());
    registerFallbackValue(
      const FetchWritingQuests(
        gameType: GameSubtype.writingEmail,
        level: 2,
      ),
    );
  });

  setUp(() async {
    mockWritingBloc = MockWritingBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();
    writingStreamController = StreamController<WritingState>.broadcast();

    // Haptics
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    // Sounds
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

    // TTS
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    // Analytics
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'we_user_1',
          email: 'we@vowl.app',
          displayName: 'Epistolary Scribe',
          hintCount: 3,
          isPremium: false,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    // Economy mock
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    // Network mock
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Writing Bloc default state
    when(() => mockWritingBloc.state).thenReturn(testLoadedState);
    when(
      () => mockWritingBloc.stream,
    ).thenAnswer((_) => writingStreamController.stream);

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await writingStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    WritingState? state,
    int level = 2,
    Size surfaceSize = const Size(390, 1000),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    bool isPremium = false,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (isPremium) {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          const UserEntity(
            id: 'we_premium_user',
            email: 'premium@vowl.app',
            displayName: 'Premium Scribe',
            hintCount: 5,
            isPremium: true,
          ),
        ),
      );
    }

    if (state != null) {
      when(() => mockWritingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<WritingBloc>.value(value: mockWritingBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: surfaceSize,
                textScaler: TextScaler.linear(textScaleFactor),
              ),
              child: WritingEmailScreen(
                level: level,
                gameType: GameSubtype.writingEmail,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> scrollAndTapOption(WidgetTester tester, String optionText) async {
    final optionFinder = find.byKey(Key('writing_email_option_$optionText'));
    await tester.ensureVisible(optionFinder);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(optionFinder);
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('WritingEmailScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all screen components properly at level 2', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byKey(const Key('writing_email_scroll_view')), findsOneWidget);
      expect(find.byType(WritingEmailInstruction), findsOneWidget);
      expect(find.byType(WritingEmailPromptCard), findsOneWidget);
      expect(find.byType(WritingEmailHexSlot), findsNWidgets(4));
      expect(find.byType(WritingEmailDataStream), findsOneWidget);

      // Verify instruction text and formality level badge
      expect(find.textContaining('FORMAL'), findsOneWidget);
      expect(find.text(sampleQuest1.prompt!), findsOneWidget);

      // Verify initial empty 4-slot structure: SUBJECT, GREETING, BODY, SIGN-OFF
      expect(find.byKey(const Key('writing_email_slot_SUBJECT')), findsOneWidget);
      expect(find.byKey(const Key('writing_email_slot_GREETING')), findsOneWidget);
      expect(find.byKey(const Key('writing_email_slot_BODY')), findsOneWidget);
      expect(find.byKey(const Key('writing_email_slot_SIGN-OFF')), findsOneWidget);

      expect(find.text('Empty slot'), findsNWidgets(4));

      // Send button is rendered
      final sendBtnFinder = find.byKey(const Key('writing_email_send_button'));
      await tester.scrollUntilVisible(
        sendBtnFinder,
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(sendBtnFinder, findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('renders formality level in instruction banner when provided', (tester) async {
      await pumpScreen(tester);
      expect(find.text('${sampleQuest1.instruction} (FORMAL)'), findsOneWidget);
    });

    testWidgets('renders fallback slot keys for non-4-option quests', (tester) async {
      const non4State = WritingLoaded(
        quests: [sampleQuest3Options],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );

      await pumpScreen(tester, state: non4State);

      expect(find.byKey(const Key('writing_email_slot_PART 1')), findsOneWidget);
      expect(find.byKey(const Key('writing_email_slot_PART 2')), findsOneWidget);
      expect(find.byKey(const Key('writing_email_slot_PART 3')), findsOneWidget);
      expect(find.text('Empty slot'), findsNWidgets(3));
    });

    testWidgets('instruction banner falls back cleanly when formalityLevel is null', (tester) async {
      const noFormalityState = WritingLoaded(
        quests: [sampleQuest3Options],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );

      await pumpScreen(tester, state: noFormalityState);
      expect(find.text(sampleQuest3Options.instruction), findsOneWidget);
    });
  });

  group('WritingEmailScreen - 2. Interactive Slotting & Removal', () {
    testWidgets('tapping an option slots it into the first available slot', (tester) async {
      await pumpScreen(tester);

      final opt0 = sampleQuest1.options![0];
      await scrollAndTapOption(tester, opt0);

      verify(() => mockHapticService.success()).called(1);

      // Slot SUBJECT now displays opt0
      expect(find.descendant(
        of: find.byKey(const Key('writing_email_slot_SUBJECT')),
        matching: find.text(opt0),
      ), findsOneWidget);

      // Remaining 3 slots are still empty
      expect(find.text('Empty slot'), findsNWidgets(3));

      // opt0 is removed from the data stream
      expect(find.byKey(Key('writing_email_option_$opt0')), findsNothing);
    });

    testWidgets('tapping all 4 options sequentially fills all slots', (tester) async {
      await pumpScreen(tester);

      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      // No empty slots remain
      expect(find.text('Empty slot'), findsNothing);

      // Data stream is removed from tree once all slots are filled
      expect(find.byType(WritingEmailDataStream), findsNothing);
    });

    testWidgets('tapping a filled slot clears it and returns option to data stream', (tester) async {
      await pumpScreen(tester);

      final opt0 = sampleQuest1.options![0];
      await scrollAndTapOption(tester, opt0);

      // Now tap slot SUBJECT to remove
      final slotSubject = find.byKey(const Key('writing_email_slot_SUBJECT'));
      await tester.ensureVisible(slotSubject);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(slotSubject);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.selection()).called(1);

      // Slot is empty again
      expect(find.descendant(
        of: slotSubject,
        matching: find.text('Empty slot'),
      ), findsOneWidget);

      // Option returns to data stream
      expect(find.byKey(Key('writing_email_option_$opt0')), findsOneWidget);
    });

    testWidgets('drag and drop accepts email part into target slot', (tester) async {
      await pumpScreen(tester);

      final opt1 = sampleQuest1.options![1];
      final targetSlotFinder = find.byKey(const Key('writing_email_slot_GREETING'));

      final hexSlot = find.ancestor(
        of: targetSlotFinder,
        matching: find.byType(WritingEmailHexSlot),
      );
      final dragTarget = tester.widget<DragTarget<String>>(
        find.descendant(
          of: hexSlot,
          matching: find.byType(DragTarget<String>),
        ),
      );

      dragTarget.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: opt1, offset: Offset.zero),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Slot GREETING contains opt1
      expect(find.descendant(
        of: targetSlotFinder,
        matching: find.text(opt1),
      ), findsOneWidget);
    });

    testWidgets('drag and drop onto already filled slot replaces it', (tester) async {
      await pumpScreen(tester);

      final opt0 = sampleQuest1.options![0];
      final opt1 = sampleQuest1.options![1];

      // Tap opt0 into SUBJECT
      await scrollAndTapOption(tester, opt0);

      final subjectSlotFinder = find.byKey(const Key('writing_email_slot_SUBJECT'));
      expect(find.descendant(
        of: subjectSlotFinder,
        matching: find.text(opt0),
      ), findsOneWidget);

      final subjectHexSlot = find.ancestor(
        of: subjectSlotFinder,
        matching: find.byType(WritingEmailHexSlot),
      );
      final subjectDragTarget = tester.widget<DragTarget<String>>(
        find.descendant(
          of: subjectHexSlot,
          matching: find.byType(DragTarget<String>),
        ),
      );

      subjectDragTarget.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: opt1, offset: Offset.zero),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // SUBJECT now contains opt1
      expect(find.descendant(
        of: subjectSlotFinder,
        matching: find.text(opt1),
      ), findsOneWidget);
    });
  });

  group('WritingEmailScreen - 3. Send Button & Validation', () {
    testWidgets('Send button is inactive and tapping does not submit answer when slots incomplete', (tester) async {
      await pumpScreen(tester);

      // Slot only first option
      await scrollAndTapOption(tester, sampleQuest1.options![0]);

      final sendBtn = find.byKey(const Key('writing_email_send_button'));
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('Send button with wrong order submission dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester);

      // Put SIGN-OFF in SUBJECT (reversed order)
      final reversedOpts = sampleQuest1.options!.reversed.toList();
      for (final opt in reversedOpts) {
        await scrollAndTapOption(tester, opt);
      }

      final sendBtn = find.byKey(const Key('writing_email_send_button'));
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.error()).called(1);
      verify(
        () => mockWritingBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
    });

    testWidgets('Send button with correct order submission dispatches SubmitAnswer(true)', (tester) async {
      await pumpScreen(tester);

      // Fill in correct order: options 0, 1, 2, 3
      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      final sendBtn = find.byKey(const Key('writing_email_send_button'));
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // 4 taps on options + 1 for correct submit = 5 calls
      verify(() => mockHapticService.success()).called(5);
      verify(
        () => mockWritingBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
        ),
      ).called(1);
    });
  });

  group('WritingEmailScreen - 4. State Transitions & Lifecycle', () {
    testWidgets('GameShimmerLoading rendered when state has no current quest', (tester) async {
      const emptyLoadedState = WritingLoaded(
        quests: [],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );

      await pumpScreen(tester, state: emptyLoadedState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(WritingEmailHexSlot), findsNothing);
    });

    testWidgets('question reset clears slots back to empty and resets answer notifiers', (tester) async {
      await pumpScreen(tester);

      final opt0 = sampleQuest1.options![0];
      await scrollAndTapOption(tester, opt0);

      expect(find.descendant(
        of: find.byKey(const Key('writing_email_slot_SUBJECT')),
        matching: find.text(opt0),
      ), findsOneWidget);

      // Transition to answered incorrect then unanswered
      const answeredState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 0,
        livesRemaining: 2,
        wrongCount: 1,
        hintUsed: false,
        answerStatus: AnswerStatus.incorrect,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(answeredState);
      writingStreamController.add(answeredState);
      await tester.pump();

      const unansweredState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 0,
        livesRemaining: 2,
        wrongCount: 1,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(unansweredState);
      writingStreamController.add(unansweredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // All slots cleared back to empty
      expect(find.text('Empty slot'), findsNWidgets(4));
    });

    testWidgets('quest progression resets slots and loads new quest prompt', (tester) async {
      await pumpScreen(tester);

      expect(find.text(sampleQuest1.prompt!), findsOneWidget);

      const nextQuestState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );

      when(() => mockWritingBloc.state).thenReturn(nextQuestState);
      writingStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(sampleQuest2.prompt!), findsOneWidget);
      expect(find.text('Empty slot'), findsNWidgets(4));
    });

    testWidgets('tapping hint button dispatches WritingHintUsed', (tester) async {
      await pumpScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockWritingBloc.add(const WritingHintUsed())).called(1);
    });

    testWidgets('feedback card renders on correct answered state and tapping continue dispatches NextQuestion', (tester) async {
      const correctState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );

      await pumpScreen(tester, state: correctState);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      await tester.tap(find.text('CONTINUE'));
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockWritingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('feedback card renders on incorrect answered state with final failure', (tester) async {
      const incorrectState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 0,
        livesRemaining: 0,
        wrongCount: 3,
        hintUsed: false,
        answerStatus: AnswerStatus.incorrect,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );

      await pumpScreen(tester, state: incorrectState);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('SEE RESULTS'), findsOneWidget);
    });

    testWidgets('WritingGameComplete displays level complete dialog', (tester) async {
      await pumpScreen(tester);

      const completeState = WritingGameComplete(
        xpEarned: 120,
        coinsEarned: 15,
        questCount: 2,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );

      when(() => mockWritingBloc.state).thenReturn(completeState);
      writingStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      final completeFinder = find.text('LEVEL COMPLETE!');
      if (completeFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(completeFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('WritingGameOver handles state gracefully', (tester) async {
      const gameOverState = WritingGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.writingEmail,
        level: 2,
      );
      await pumpScreen(tester, state: gameOverState);

      expect(find.byType(WritingEmailScreen), findsOneWidget);
    });
  });

  group('WritingEmailScreen - 5. Responsiveness & Accessibility', () {
    testWidgets('renders cleanly on small screen (320x568) without overflow', (tester) async {
      await pumpScreen(tester, surfaceSize: const Size(320, 568));

      expect(find.byType(WritingEmailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet screen (800x1280)', (tester) async {
      await pumpScreen(tester, surfaceSize: const Size(800, 1280));

      expect(find.byType(WritingEmailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x text scale factor', (tester) async {
      await pumpScreen(tester, textScaleFactor: 1.3);

      expect(find.byType(WritingEmailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with light theme', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(find.byType(WritingEmailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with level 1 theme', (tester) async {
      await pumpScreen(tester, level: 1);

      expect(find.byType(WritingEmailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accessible semantics on slots and data stream chips', (tester) async {
      await pumpScreen(tester);

      expect(
        find.bySemanticsLabel(RegExp(r'Slot for SUBJECT')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Email part:')),
        findsWidgets,
      );
    });
  });
}

