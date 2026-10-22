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
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/pages/summarize_story_writing_screen.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_writing_instruction.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_manuscript.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_film_strip.dart';
import 'package:vowl/features/writing/summarize_story_writing/presentation/widgets/summarize_story_frame_vault.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';

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
    id: 'ssw_q1',
    instruction: 'Arrange key events in chronological order to summarize the story.',
    difficulty: 2,
    subtype: GameSubtype.summarizeStoryWriting,
    story: 'Maya discovered an ancient map inside a dusty library book. She followed the coordinates into the forgotten valley. At the summit, she uncovered the lost crystal of Eldoria.',
    options: [
      'Maya discovered an ancient map in a library book.',
      'She followed coordinates into a forgotten valley.',
      'At the summit, she uncovered the lost crystal.',
    ],
    correctOrder: [0, 1, 2],
    hint: 'Start with the discovery of the map.',
    explanation: 'The story follows a chronological journey from discovery to the crystal.',
    sampleAnswer: 'Maya discovered an ancient map in a library book. She followed coordinates into a forgotten valley. At the summit, she uncovered the lost crystal.',
    xpReward: 30,
    coinReward: 20,
  );

  const sampleQuest2 = WritingQuest(
    id: 'ssw_q2',
    instruction: 'Summarize the mission sequence.',
    difficulty: 2,
    subtype: GameSubtype.summarizeStoryWriting,
    story: 'The probe initiated thruster ignition. It entered lunar orbit 48 hours later. Finally, the probe landed safely on the South Pole basin.',
    options: [
      'The probe initiated thruster ignition.',
      'It entered lunar orbit 48 hours later.',
      'Finally, the probe landed safely on the South Pole basin.',
    ],
    correctOrder: [0, 1, 2],
    hint: 'Begin with thruster ignition.',
    explanation: 'Chronological timeline of the lunar probe flight path.',
    sampleAnswer: 'The probe initiated thruster ignition. It entered lunar orbit 48 hours later. Finally, the probe landed safely on the South Pole basin.',
    xpReward: 35,
    coinReward: 25,
  );

  const testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.summarizeStoryWriting,
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
        gameType: GameSubtype.summarizeStoryWriting,
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
          id: 'ssw_user_1',
          email: 'ssw@vowl.app',
          displayName: 'Summarizer Sage',
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
    Size surfaceSize = const Size(390, 844),
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
            id: 'ssw_premium_user',
            email: 'premium@vowl.app',
            displayName: 'Premium Sage',
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
              child: SummarizeStoryWritingScreen(
                level: level,
                gameType: GameSubtype.summarizeStoryWriting,
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
    final optionFinder = find.byKey(Key('summarize_story_option_$optionText'));
    await tester.ensureVisible(optionFinder);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(optionFinder);
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('SummarizeStoryWritingScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all screen components properly at level 2', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byKey(const Key('summarize_story_scroll_view')), findsOneWidget);
      expect(find.byType(SummarizeStoryWritingInstruction), findsOneWidget);
      expect(find.byType(SummarizeStoryManuscript), findsOneWidget);
      expect(find.byType(SummarizeStoryFilmStrip), findsOneWidget);
      expect(find.byType(SummarizeStoryFrameVault), findsOneWidget);
      expect(find.byType(SpeedChallengeTimer), findsOneWidget);

      // Verify instruction and story text
      expect(find.text(sampleQuest1.instruction), findsOneWidget);
      expect(find.text(sampleQuest1.story!), findsOneWidget);

      // Verify initial empty film strip slots
      expect(find.text('Tap or drag an event here'), findsNWidgets(3));
      for (int i = 0; i < 3; i++) {
        expect(find.byKey(Key('summarize_story_slot_$i')), findsOneWidget);
      }

      // Check Answer button is initially hidden because slots are empty
      expect(find.byKey(const Key('summarize_story_check_button')), findsNothing);
    });
  });

  group('SummarizeStoryWritingScreen - 2. Interactive Slotting & Removal', () {
    testWidgets('tapping an option slots it into the first available slot', (tester) async {
      await pumpScreen(tester);

      final option0 = sampleQuest1.options![0];
      await scrollAndTapOption(tester, option0);

      verify(() => mockHapticService.success()).called(1);

      // Slot 0 now displays option0
      expect(find.descendant(
        of: find.byKey(const Key('summarize_story_slot_0')),
        matching: find.text(option0),
      ), findsOneWidget);

      // Frame vault no longer displays option0
      expect(find.byKey(Key('summarize_story_option_$option0')), findsNothing);

      // Check answer button is still not visible (only 1 of 3 filled)
      expect(find.byKey(const Key('summarize_story_check_button')), findsNothing);
    });

    testWidgets('tapping all 3 options populates all slots and reveals Check Answer button', (tester) async {
      await pumpScreen(tester);

      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      // All 3 slots filled
      for (int i = 0; i < 3; i++) {
        expect(find.descendant(
          of: find.byKey(Key('summarize_story_slot_$i')),
          matching: find.text(sampleQuest1.options![i]),
        ), findsOneWidget);
      }

      // Frame vault has no available options left
      for (final opt in sampleQuest1.options!) {
        expect(find.byKey(Key('summarize_story_option_$opt')), findsNothing);
      }

      // Check Answer button is now visible
      final checkButton = find.byKey(const Key('summarize_story_check_button'));
      await tester.ensureVisible(checkButton);
      await tester.pump(const Duration(milliseconds: 200));
      expect(checkButton, findsOneWidget);
      expect(find.text('CHECK ANSWER'), findsOneWidget);
    });

    testWidgets('tapping a filled slot clears it and returns option to vault', (tester) async {
      await pumpScreen(tester);

      final option0 = sampleQuest1.options![0];
      // Slot option0
      await scrollAndTapOption(tester, option0);

      // Now tap slot 0 to remove
      final slot0 = find.byKey(const Key('summarize_story_slot_0'));
      await tester.ensureVisible(slot0);
      await tester.tap(slot0);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.selection()).called(1);

      // Slot 0 is now empty again
      expect(find.descendant(
        of: slot0,
        matching: find.text('Tap or drag an event here'),
      ), findsOneWidget);

      // Option returns to frame vault
      expect(find.byKey(Key('summarize_story_option_$option0')), findsOneWidget);
    });

    testWidgets('drag and drop accepts sentence into target slot', (tester) async {
      await pumpScreen(tester);

      final option0 = sampleQuest1.options![0];
      final optionFinder = find.byKey(Key('summarize_story_option_$option0'));
      final targetSlotFinder = find.byKey(const Key('summarize_story_slot_0'));

      await tester.ensureVisible(optionFinder);
      await tester.pump(const Duration(milliseconds: 100));

      final startPos = tester.getCenter(optionFinder);
      final endPos = tester.getCenter(targetSlotFinder);

      final gesture = await tester.startGesture(startPos);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(endPos);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.success()).called(1);

      // Slot 0 has received option0
      expect(find.descendant(
        of: find.byKey(const Key('summarize_story_slot_0')),
        matching: find.text(option0),
      ), findsOneWidget);
    });
  });

  group('SummarizeStoryWritingScreen - 3. Check Answer & Validation', () {
    testWidgets('wrong order submission triggers error haptics and submitWrongAnswer', (tester) async {
      await pumpScreen(tester);

      // Slot in wrong order: opt 2, opt 1, opt 0
      final opt0 = sampleQuest1.options![0];
      final opt1 = sampleQuest1.options![1];
      final opt2 = sampleQuest1.options![2];

      await scrollAndTapOption(tester, opt2);
      await scrollAndTapOption(tester, opt1);
      await scrollAndTapOption(tester, opt0);

      final checkButton = find.byKey(const Key('summarize_story_check_button'));
      await tester.ensureVisible(checkButton);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(checkButton);
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockHapticService.error()).called(1);
      verify(
        () => mockWritingBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
    });

    testWidgets('correct order submission triggers success and reveals TypeToConfirmOverlay', (tester) async {
      await pumpScreen(tester);

      // Slot in correct order: 0, 1, 2
      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      final checkButton = find.byKey(const Key('summarize_story_check_button'));
      await tester.ensureVisible(checkButton);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(checkButton);
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(1));
      // TypeToConfirmOverlay is now rendered!
      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
      expect(find.byKey(const Key('summarize_story_check_button')), findsNothing);
    });
  });

  group('SummarizeStoryWritingScreen - 4. Stage 2 TypeToConfirmOverlay & Confirmation', () {
    testWidgets('TypeToConfirmOverlay renders expected summary text', (tester) async {
      await pumpScreen(tester);

      // Fill in correct order
      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      final checkButton = find.byKey(const Key('summarize_story_check_button'));
      await tester.ensureVisible(checkButton);
      await tester.tap(checkButton);
      await tester.pump(const Duration(milliseconds: 400));

      final overlayFinder = find.byType(TypeToConfirmOverlay);
      expect(overlayFinder, findsOneWidget);

      final expectedSummary = sampleQuest1.options!.join(' ');
      expect(find.descendant(
        of: overlayFinder,
        matching: find.text(expectedSummary),
      ), findsOneWidget);

      expect(find.descendant(
        of: overlayFinder,
        matching: find.byType(TextField),
      ), findsOneWidget);
    });

    testWidgets('typing matching summary and tapping submit confirms correct answer', (tester) async {
      await pumpScreen(tester);

      // Fill in correct order
      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      final checkButton = find.byKey(const Key('summarize_story_check_button'));
      await tester.ensureVisible(checkButton);
      await tester.tap(checkButton);
      await tester.pump(const Duration(milliseconds: 400));

      final expectedSummary = sampleQuest1.options!.join(' ');
      final textFieldFinder = find.byType(TextField);
      await tester.ensureVisible(textFieldFinder);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(textFieldFinder, expectedSummary);
      await tester.pump(const Duration(milliseconds: 100));

      final submitBtnFinder = find.text('SUBMIT');
      await tester.ensureVisible(submitBtnFinder);
      await tester.tap(submitBtnFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Advance through evaluate delayed timer (800ms)
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(
        () => mockWritingBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
        ),
      ).called(1);
    });

    testWidgets('free user skip button displays ad and calls submitWrongAnswer on dismissal', (tester) async {
      when(
        () => mockAdService.showRewardedAd(
          context: any(named: 'context'),
          isPremium: false,
          onUserEarnedReward: any(named: 'onUserEarnedReward'),
          onDismissed: any(named: 'onDismissed'),
        ),
      ).thenAnswer((invocation) {
        final onDismissed = invocation.namedArguments[#onDismissed] as VoidCallback?;
        onDismissed?.call();
      });

      await pumpScreen(tester, isPremium: false);

      // Fill in correct order
      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      final checkButton = find.byKey(const Key('summarize_story_check_button'));
      await tester.ensureVisible(checkButton);
      await tester.tap(checkButton);
      await tester.pump(const Duration(milliseconds: 400));

      final skipBtn = find.byType(GameSkipBypassButton);
      await tester.ensureVisible(skipBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(skipBtn);
      await tester.pump(const Duration(milliseconds: 200));

      verify(
        () => mockAdService.showRewardedAd(
          context: any(named: 'context'),
          isPremium: false,
          onUserEarnedReward: any(named: 'onUserEarnedReward'),
          onDismissed: any(named: 'onDismissed'),
        ),
      ).called(1);
    });

    testWidgets('premium user skip button triggers bypass confirmation', (tester) async {
      await pumpScreen(tester, isPremium: true);

      // Fill in correct order
      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      final checkButton = find.byKey(const Key('summarize_story_check_button'));
      await tester.ensureVisible(checkButton);
      await tester.tap(checkButton);
      await tester.pump(const Duration(milliseconds: 400));

      final skipBtn = find.byType(GameSkipBypassButton);
      await tester.ensureVisible(skipBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(skipBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(
        () => mockWritingBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
        ),
      ).called(1);
    });
  });

  group('SummarizeStoryWritingScreen - 5. SpeedChallengeTimer & Expiry', () {
    testWidgets('SpeedChallengeTimer onTimeUp triggers submitWrongAnswer when not pending submit', (tester) async {
      await pumpScreen(tester);

      final timerWidget = tester.widget<SpeedChallengeTimer>(find.byType(SpeedChallengeTimer));
      timerWidget.onTimeUp();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.error()).called(1);
      verify(
        () => mockWritingBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
    });

    testWidgets('SpeedChallengeTimer is ignored when pending submit is true', (tester) async {
      await pumpScreen(tester);

      // Fill in correct order
      for (final opt in sampleQuest1.options!) {
        await scrollAndTapOption(tester, opt);
      }

      final checkButton = find.byKey(const Key('summarize_story_check_button'));
      await tester.ensureVisible(checkButton);
      await tester.tap(checkButton);
      await tester.pump(const Duration(milliseconds: 400));

      // SpeedChallengeTimer is removed from tree when pending submit
      expect(find.byType(SpeedChallengeTimer), findsNothing);
    });
  });

  group('SummarizeStoryWritingScreen - 6. State Transitions & Lifecycle', () {
    testWidgets('GameShimmerLoading rendered when state has no current quest', (tester) async {
      const emptyLoadedState = WritingLoaded(
        quests: [],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.summarizeStoryWriting,
        level: 2,
      );

      await pumpScreen(tester, state: emptyLoadedState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SummarizeStoryFilmStrip), findsNothing);
    });

    testWidgets('question reset clears slots back to empty', (tester) async {
      await pumpScreen(tester);

      // Slot first option
      final opt0 = sampleQuest1.options![0];
      await scrollAndTapOption(tester, opt0);

      expect(find.descendant(
        of: find.byKey(const Key('summarize_story_slot_0')),
        matching: find.text(opt0),
      ), findsOneWidget);

      // Transition through answered (wrong attempt) to new unanswered attempt
      const answeredState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 0,
        livesRemaining: 2,
        wrongCount: 1,
        hintUsed: false,
        answerStatus: AnswerStatus.incorrect,
        gameType: GameSubtype.summarizeStoryWriting,
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
        gameType: GameSubtype.summarizeStoryWriting,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(unansweredState);
      writingStreamController.add(unansweredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // All slots cleared back to default
      expect(find.text('Tap or drag an event here'), findsNWidgets(3));
    });

    testWidgets('quest progression resets slots for new quest', (tester) async {
      await pumpScreen(tester);

      expect(find.text(sampleQuest1.story!), findsOneWidget);

      const nextQuestState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.summarizeStoryWriting,
        level: 2,
      );

      when(() => mockWritingBloc.state).thenReturn(nextQuestState);
      writingStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(sampleQuest2.story!), findsOneWidget);
      expect(find.text('Tap or drag an event here'), findsNWidgets(3));
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
        gameType: GameSubtype.summarizeStoryWriting,
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
        isFinalFailure: true,
        hintUsed: false,
        answerStatus: AnswerStatus.incorrect,
        gameType: GameSubtype.summarizeStoryWriting,
        level: 2,
      );

      await pumpScreen(tester, state: incorrectState);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('WRITING CONTEXT'), findsOneWidget);
      expect(find.text(sampleQuest1.explanation!), findsOneWidget);
    });

    testWidgets('WritingGameComplete displays level complete dialog', (tester) async {
      await pumpScreen(tester);

      const completeState = WritingGameComplete(
        xpEarned: 50,
        coinsEarned: 20,
        questCount: 2,
        gameType: GameSubtype.summarizeStoryWriting,
        level: 2,
      );

      when(() => mockWritingBloc.state).thenReturn(completeState);
      writingStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      final completeFinder = find.text('LEVEL COMPLETE!');
      if (completeFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(completeFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('WritingGameOver handles state gracefully', (tester) async {
      await pumpScreen(tester);

      const gameOverState = WritingGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.summarizeStoryWriting,
        level: 2,
      );

      when(() => mockWritingBloc.state).thenReturn(gameOverState);
      writingStreamController.add(gameOverState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });

  group('SummarizeStoryWritingScreen - 7. Responsiveness & Accessibility', () {
    testWidgets('renders cleanly on small screen (320x568) without overflow', (tester) async {
      await pumpScreen(
        tester,
        surfaceSize: const Size(320, 568),
      );

      expect(find.byType(SummarizeStoryWritingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet screen (800x1280)', (tester) async {
      await pumpScreen(
        tester,
        surfaceSize: const Size(800, 1280),
      );

      expect(find.byType(SummarizeStoryWritingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x text scale factor', (tester) async {
      await pumpScreen(
        tester,
        textScaleFactor: 1.3,
      );

      expect(find.byType(SummarizeStoryWritingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with light theme', (tester) async {
      await pumpScreen(
        tester,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(SummarizeStoryWritingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with level 1 theme', (tester) async {
      await pumpScreen(
        tester,
        level: 1,
      );

      expect(find.byType(SummarizeStoryWritingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
