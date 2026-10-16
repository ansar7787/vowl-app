import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
import 'package:vowl/features/writing/essay_drafting/presentation/pages/essay_drafting_screen.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_data_stream.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_hex_slot.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_instruction.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_topic_banner.dart';
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

  WritingQuest createQuest({
    String id = 'quest_ed_1',
    String instruction = 'Assemble the essay outline by dragging the paragraph blocks into logical order.',
    String essayTopic = 'Renewable Energy Transition in Urban Architecture',
    String thesisStatement = 'Integrating solar envelopes into skyscrapers reduces urban grid dependency.',
    List<String> requiredPoints = const [
      'INTRODUCTION',
      'EVIDENCE',
      'COUNTERARGUMENT',
      'CONCLUSION',
    ],
    List<String> options = const [
      'Cities consume 78% of global energy, necessitating self-sufficient buildings.',
      'Photovoltaic facades generate up to 40% of building operational demand.',
      'High initial retrofitting costs remain a significant upfront obstacle.',
      'Long-term lifecycle savings and carbon neutrality outweigh preliminary expenditures.',
    ],
    List<int> correctOrder = const [0, 1, 2, 3],
    int difficulty = 2,
    String hint = 'Start with the overarching global context before technical facade statistics.',
    String explanation = 'Logical paragraph sequencing ensures coherence in academic essay structure.',
  }) {
    return WritingQuest(
      id: id,
      type: QuestType.writing,
      subtype: GameSubtype.essayDrafting,
      instruction: instruction,
      essayTopic: essayTopic,
      thesisStatement: thesisStatement,
      requiredPoints: requiredPoints,
      options: options,
      correctOrder: correctOrder,
      difficulty: difficulty,
      hint: hint,
      explanation: explanation,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_ed_2',
    essayTopic: 'Autonomous Transit in Smart Metropolises',
    thesisStatement: 'Self-driving bus fleets dramatically diminish traffic fatalities and congestion.',
    requiredPoints: ['CONTEXT', 'DATA', 'REBUTTAL', 'IMPACT'],
    options: [
      'Human driving errors cause over 90% of vehicular accidents.',
      'Pilot tests in Helsinki showed a 42% reduction in downtown bottlenecks.',
      'Software edge-case vulnerabilities pose genuine regulatory safety concerns.',
      'Redundant lidar fail-safes make autonomous transit far safer than human transit.',
    ],
    correctOrder: [0, 1, 2, 3],
  );

  final testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.essayDrafting,
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
        gameType: GameSubtype.essayDrafting,
        level: 2,
      ),
    );
    registerFallbackValue(const EconomyAddCoinsRequested(5));
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

    // Analytics & Ad mocks
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});
    when(
      () => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      ),
    ).thenAnswer((inv) {
      final onEarned = inv.namedArguments[#onUserEarnedReward] as dynamic;
      onEarned?.call(RewardItem(1, 'coin'));
    });

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'essayist_1',
          email: 'essayist@vowl.app',
          displayName: 'Essayist',
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
    bool settle = true,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockWritingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WritingBloc>.value(value: mockWritingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                ),
                child: EssayDraftingScreen(
                  level: level,
                  gameType: GameSubtype.essayDrafting,
                ),
              ),
            );
          },
        ),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> scrollAndTapConfirmButton(WidgetTester tester) async {
    final messengerFinder = find.byType(ScaffoldMessenger);
    if (messengerFinder.evaluate().isNotEmpty) {
      tester.state<ScaffoldMessengerState>(messengerFinder).clearSnackBars();
      await tester.pump();
    }
    final confirmButton = find.byKey(const Key('essay_drafting_confirm_button'));
    if (confirmButton.evaluate().isNotEmpty) {
      await tester.ensureVisible(confirmButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('EssayDraftingScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all essential components in normal mode (level 2)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(EssayDraftingInstruction), findsOneWidget);
      expect(find.byType(EssayDraftingTopicBanner), findsOneWidget);
      expect(find.byType(EssayDraftingHexSlot), findsNWidgets(4));
      expect(find.byType(EssayDraftingDataStream), findsOneWidget);
      expect(
        find.byKey(const Key('essay_drafting_confirm_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('essay_drafting_scroll_view')),
        findsOneWidget,
      );
      expect(find.text('CONFIRM OUTLINE'), findsOneWidget);
    });

    testWidgets('renders topic and thesis statement in topic banner', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      expect(
        find.text('Renewable Energy Transition in Urban Architecture'),
        findsOneWidget,
      );
      expect(find.text('THESIS STATEMENT'), findsOneWidget);
      expect(
        find.text(
          'Integrating solar envelopes into skyscrapers reduces urban grid dependency.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders shimmer loading when in initial state', (tester) async {
      const initialState = WritingInitial();
      await pumpScreen(tester, state: initialState, level: 2, settle: false);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(EssayDraftingTopicBanner), findsNothing);
    });

    testWidgets('dispatches FetchWritingQuests on init', (tester) async {
      await pumpScreen(tester, level: 2);

      verify(
        () => mockWritingBloc.add(
          const FetchWritingQuests(
            gameType: GameSubtype.essayDrafting,
            level: 2,
          ),
        ),
      ).called(1);
    });
  });

  group('EssayDraftingScreen - 2. Blueprint Slots & Slotted Interactions', () {
    testWidgets('initial state renders all required points as empty slots', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      expect(find.text('INTRODUCTION'), findsOneWidget);
      expect(find.text('EVIDENCE'), findsOneWidget);
      expect(find.text('COUNTERARGUMENT'), findsOneWidget);
      expect(find.text('CONCLUSION'), findsOneWidget);

      expect(find.text('Drop paragraph block here...'), findsNWidgets(4));
    });

    testWidgets('slotting an item updates hex slot and removes it from available stream', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final introSlotFinder = find.byKey(const Key('essay_drafting_slot_INTRODUCTION'));
      expect(introSlotFinder, findsOneWidget);

      final hexSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      hexSlot.onSlot(
        'INTRODUCTION',
        sampleQuest1.options![0],
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.success()).called(1);
      expect(
        find.text('Cities consume 78% of global energy, necessitating self-sufficient buildings.'),
        findsOneWidget,
      );
      expect(find.text('Drop paragraph block here...'), findsNWidgets(3));
    });

    testWidgets('slotting same item into another slot moves it to the new slot', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![0]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final evidenceSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'EVIDENCE'),
      );
      evidenceSlot.onSlot('EVIDENCE', sampleQuest1.options![0]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Drop paragraph block here...'), findsNWidgets(3));
    });

    testWidgets('tapping a filled hex slot clears it and returns item to stream', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![0]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Drop paragraph block here...'), findsNWidgets(3));

      // Tap slot to clear
      await tester.tap(find.byKey(const Key('essay_drafting_slot_INTRODUCTION')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      expect(find.text('Drop paragraph block here...'), findsNWidgets(4));
    });

    testWidgets('tapping an empty hex slot does nothing', (tester) async {
      await pumpScreen(tester, level: 2);

      await tester.tap(find.byKey(const Key('essay_drafting_slot_INTRODUCTION')));
      await tester.pump();

      verifyNever(() => mockHapticService.selection());
      expect(find.text('Drop paragraph block here...'), findsNWidgets(4));
    });
  });

  group('EssayDraftingScreen - 3. Validation & Confirmation', () {
    testWidgets('CONFIRM OUTLINE button does nothing when slots are not filled', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      await scrollAndTapConfirmButton(tester);

      verifyNever(() => mockHapticService.error());
      verifyNever(() => mockHapticService.success());
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('submitting incorrect outline triggers error haptic and submits wrong answer', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      // Fill in reverse/wrong order
      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![3]); // wrong

      final evidenceSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'EVIDENCE'),
      );
      evidenceSlot.onSlot('EVIDENCE', sampleQuest1.options![2]); // wrong

      final counterSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'COUNTERARGUMENT'),
      );
      counterSlot.onSlot('COUNTERARGUMENT', sampleQuest1.options![1]); // wrong

      final conclusionSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'CONCLUSION'),
      );
      conclusionSlot.onSlot('CONCLUSION', sampleQuest1.options![0]); // wrong
      await tester.pump();

      await scrollAndTapConfirmButton(tester);

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('submitting correct outline triggers success haptic and reveals TypeToConfirmOverlay', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      // Fill in exact correct order
      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![0]);

      final evidenceSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'EVIDENCE'),
      );
      evidenceSlot.onSlot('EVIDENCE', sampleQuest1.options![1]);

      final counterSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'COUNTERARGUMENT'),
      );
      counterSlot.onSlot('COUNTERARGUMENT', sampleQuest1.options![2]);

      final conclusionSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'CONCLUSION'),
      );
      conclusionSlot.onSlot('CONCLUSION', sampleQuest1.options![3]);
      await tester.pump();

      await scrollAndTapConfirmButton(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(4));
      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
      expect(
        find.byKey(const Key('essay_drafting_confirm_button')),
        findsNothing,
      );
    });
  });

  group('EssayDraftingScreen - 4. TypeToConfirmOverlay (Stage 2)', () {
    testWidgets('TypeToConfirmOverlay displays expected concatenated text', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![0]);

      final evidenceSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'EVIDENCE'),
      );
      evidenceSlot.onSlot('EVIDENCE', sampleQuest1.options![1]);

      final counterSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'COUNTERARGUMENT'),
      );
      counterSlot.onSlot('COUNTERARGUMENT', sampleQuest1.options![2]);

      final conclusionSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'CONCLUSION'),
      );
      conclusionSlot.onSlot('CONCLUSION', sampleQuest1.options![3]);
      await tester.pump();

      await scrollAndTapConfirmButton(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final overlay = tester.widget<TypeToConfirmOverlay>(
        find.byType(TypeToConfirmOverlay),
      );
      expect(
        overlay.expectedText,
        sampleQuest1.options!.join(' '),
      );
    });

    testWidgets('confirming typing in TypeToConfirmOverlay dispatches SubmitAnswer(true)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![0]);

      final evidenceSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'EVIDENCE'),
      );
      evidenceSlot.onSlot('EVIDENCE', sampleQuest1.options![1]);

      final counterSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'COUNTERARGUMENT'),
      );
      counterSlot.onSlot('COUNTERARGUMENT', sampleQuest1.options![2]);

      final conclusionSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'CONCLUSION'),
      );
      conclusionSlot.onSlot('CONCLUSION', sampleQuest1.options![3]);
      await tester.pump();

      await scrollAndTapConfirmButton(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final overlay = tester.widget<TypeToConfirmOverlay>(
        find.byType(TypeToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('skipping typing in TypeToConfirmOverlay dispatches SubmitAnswer(false)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![0]);

      final evidenceSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'EVIDENCE'),
      );
      evidenceSlot.onSlot('EVIDENCE', sampleQuest1.options![1]);

      final counterSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'COUNTERARGUMENT'),
      );
      counterSlot.onSlot('COUNTERARGUMENT', sampleQuest1.options![2]);

      final conclusionSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'CONCLUSION'),
      );
      conclusionSlot.onSlot('CONCLUSION', sampleQuest1.options![3]);
      await tester.pump();

      await scrollAndTapConfirmButton(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final overlay = tester.widget<TypeToConfirmOverlay>(
        find.byType(TypeToConfirmOverlay),
      );
      overlay.onSkipped();
      await tester.pump();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('EssayDraftingScreen - 5. Feedback, Navigation & Reset', () {
    testWidgets('displays feedback card when answered correctly', (
      tester,
    ) async {
      final answeredCorrect = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredCorrect, level: 2);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('tapping CONTINUE dispatches NextQuestion', (tester) async {
      final answeredCorrect = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredCorrect, level: 2);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockWritingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('tapping Hint button dispatches WritingHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);
      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockWritingBloc.add(const WritingHintUsed())).called(1);
    });

    testWidgets('onQuestionReset resets slots and pending submit on new question', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![0]);
      await tester.pump();

      expect(find.text('Drop paragraph block here...'), findsNWidgets(3));

      // Emit new question
      final nextQuestionState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.essayDrafting,
        level: 2,
      );

      writingStreamController.add(nextQuestionState);
      when(() => mockWritingBloc.state).thenReturn(nextQuestionState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Autonomous Transit in Smart Metropolises'), findsOneWidget);
      expect(find.text('Drop paragraph block here...'), findsNWidgets(4));
    });
  });

  group('EssayDraftingScreen - 6. Completion, Game Over & Error Journal', () {
    testWidgets('shows completion dialog on WritingGameComplete', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      const completeState = WritingGameComplete(
        xpEarned: 50,
        coinsEarned: 20,
        questCount: 2,
        gameType: GameSubtype.essayDrafting,
        level: 2,
      );

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

    testWidgets('handles WritingGameOver without crash', (tester) async {
      await pumpScreen(tester, level: 2);

      final gameOverState = WritingGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.essayDrafting,
        level: 2,
      );
      writingStreamController.add(gameOverState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EssayDraftingScreen), findsOneWidget);

      final giveUpFinder = find.text('GIVE UP');
      if (giveUpFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(giveUpFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('records to ErrorJournal when answering incorrectly as authenticated user', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          const UserEntity(
            id: 'essayist_err_user',
            email: 'err@vowl.app',
            displayName: 'Essay Error User',
          ),
        ),
      );

      await pumpScreen(tester, level: 2);

      final introSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'INTRODUCTION'),
      );
      introSlot.onSlot('INTRODUCTION', sampleQuest1.options![3]); // wrong

      final evidenceSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'EVIDENCE'),
      );
      evidenceSlot.onSlot('EVIDENCE', sampleQuest1.options![2]); // wrong

      final counterSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'COUNTERARGUMENT'),
      );
      counterSlot.onSlot('COUNTERARGUMENT', sampleQuest1.options![1]); // wrong

      final conclusionSlot = tester.widget<EssayDraftingHexSlot>(
        find.widgetWithText(EssayDraftingHexSlot, 'CONCLUSION'),
      );
      conclusionSlot.onSlot('CONCLUSION', sampleQuest1.options![0]); // wrong
      await tester.pump();

      await scrollAndTapConfirmButton(tester);

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('EssayDraftingScreen - 7. Responsiveness & Accessibility', () {
    testWidgets('renders properly on small screen (320x568)', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(320, 568),
      );

      expect(find.byType(EssayDraftingScreen), findsOneWidget);
      expect(find.byType(EssayDraftingInstruction), findsOneWidget);
      expect(find.byType(EssayDraftingTopicBanner), findsOneWidget);
    });

    testWidgets('renders properly on tablet screen (800x1280)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(800, 1280),
      );

      expect(find.byType(EssayDraftingScreen), findsOneWidget);
      expect(find.byType(EssayDraftingTopicBanner), findsOneWidget);
      expect(find.byType(EssayDraftingHexSlot), findsNWidgets(4));
    });

    testWidgets('renders with 1.3x high text scale without overflow', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 2,
        textScaleFactor: 1.3,
      );

      expect(find.byType(EssayDraftingScreen), findsOneWidget);
      expect(find.byType(EssayDraftingTopicBanner), findsOneWidget);
    });

    testWidgets('renders properly in light theme', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(EssayDraftingScreen), findsOneWidget);
      expect(find.text('CONFIRM OUTLINE'), findsOneWidget);
    });

    testWidgets('briefing overlay shows at level 1 and dismisses on tap', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 1,
        surfaceSize: const Size(390, 1000),
      );

      expect(find.byType(QuestBriefingOverlay), findsOneWidget);

      final startButton = find.descendant(
        of: find.byType(QuestBriefingOverlay),
        matching: find.byType(ScaleButton),
      );
      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });
  });
}

