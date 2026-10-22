import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/pages/travel_desk_screen.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_customs_terminal.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_passport_book.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_stamp_painter.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_stamp_station.dart';

class MockRoleplayBloc extends MockBloc<RoleplayEvent, RoleplayState>
    implements RoleplayBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockSpeechService extends Mock implements SpeechService {}

class MockAudioRecordingService extends Mock implements AudioRecordingService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

RoleplayQuest createQuest({
  String id = 'td_1',
  String prompt = 'I need to board the train to Tokyo Station.',
  List<String> options = const [
    'Tokyo Express',
    'Kyoto Shinkansen',
    'Osaka Metro',
  ],
  int correctAnswerIndex = 0,
  String? correctAnswer = 'Tokyo Express',
  String? explanation =
      'Confirming the correct rail transit line ensures on-time arrival.',
  String? culturalNote =
      'Japanese rail transit requires precise platform and train type awareness.',
  String? travelDocuments = 'JAPAN RAIL PASS BOOKLET',
  List<String>? itinerary,
  String instruction = 'Direct the traveler to their target departure transit line',
  int difficulty = 2,
}) {
  return RoleplayQuest(
    id: id,
    type: QuestType.roleplay,
    subtype: GameSubtype.travelDesk,
    prompt: prompt,
    options: options,
    correctAnswerIndex: correctAnswerIndex,
    correctAnswer: correctAnswer,
    explanation: explanation,
    culturalNote: culturalNote,
    travelDocuments: travelDocuments,
    itinerary: itinerary,
    instruction: instruction,
    difficulty: difficulty,
  );
}

void main() {
  late MockRoleplayBloc mockRoleplayBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockSpeechService mockSpeechService;
  late MockAudioRecordingService mockAudioRecorder;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<RoleplayState> roleplayStreamController;

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'td_2',
    prompt: 'Excuse me, which flight heads directly to London Heathrow?',
    options: const [
      'Flight BA-142',
      'Flight AF-308',
      'Flight LH-990',
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'Flight BA-142',
    explanation: 'Flight numbers designate specific international air corridors.',
    culturalNote: 'International terminals require confirming gate and flight codes.',
    travelDocuments: 'BRITISH AIRWAYS BOARDING FOLIO',
    instruction: 'Identify the direct flight connection for the passenger',
  );

  final testLoadedState = RoleplayLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.travelDesk,
    level: 2,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const RoleplayHintUsed());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const RoleplaySpeakConfirmed(5));
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_travelDesk': true,
    });

    mockRoleplayBloc = MockRoleplayBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockSpeechService = MockSpeechService();
    mockAudioRecorder = MockAudioRecordingService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();
    roleplayStreamController = StreamController<RoleplayState>.broadcast();

    // Default Stubs
    when(() => mockRoleplayBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockRoleplayBloc,
      roleplayStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user',
          email: 'test@vowl.app',
          displayName: 'Test Explorer',
          isPremium: true,
          hintCount: 3,
        ),
      ),
    );

    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
    when(() => mockSoundService.playUrl(any())).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockTtsService.speak(
      any(),
      rate: any(named: 'rate'),
      locale: any(named: 'locale'),
    )).thenAnswer((_) async {});

    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => '/tmp/travel_desk_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.onAmplitudeChanged(any()))
        .thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(any(), fallback: any(named: 'fallback')))
        .thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      return fallback ?? invocation.positionalArguments[0] as String;
    });

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockAnalyticsService.logSelfEvaluation(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalyticsService.logPurchaseAttempt(any()))
        .thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() {
    roleplayStreamController.close();
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
  });

  Future<void> pumpTravelDeskScreen(
    WidgetTester tester, {
    RoleplayState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 1400),
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final activeState = state ?? testLoadedState;
    when(() => mockRoleplayBloc.state).thenReturn(activeState);
    whenListen(
      mockRoleplayBloc,
      roleplayStreamController.stream,
      initialState: activeState,
    );
    if (!roleplayStreamController.isClosed) {
      roleplayStreamController.add(activeState);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<RoleplayBloc>.value(value: mockRoleplayBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: size,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                disableAnimations: reduceMotion,
              ),
              child: TravelDeskScreen(
                level: level,
                gameType: GameSubtype.travelDesk,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('TravelDeskScreen Layout and Mechanics Tests', () {
    // -------------------------------------------------------------------------
    // 1. Initial Layout & Structural Components (Tests 1-8)
    // -------------------------------------------------------------------------

    testWidgets('1. Initial layout renders RoleplayBaseLayout and progress header',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.byType(RoleplayBaseLayout), findsOneWidget);
      expect(find.byType(GameProgressHeader), findsOneWidget);
    });

    testWidgets('2. Initial layout renders TravelDeskCustomsTerminal',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.byType(TravelDeskCustomsTerminal), findsOneWidget);
    });

    testWidgets('3. Customs terminal displays formatted instruction text',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(
        find.text('Direct the traveler to their target departure transit line'),
        findsOneWidget,
      );
    });

    testWidgets('4. Customs terminal renders fallback instruction text when quest instruction is empty',
        (tester) async {
      final fallbackQuest = createQuest(instruction: '');
      final state = testLoadedState.copyWith(quests: [fallbackQuest]);
      await pumpTravelDeskScreen(tester, state: state);

      expect(find.byType(TravelDeskCustomsTerminal), findsOneWidget);
    });

    testWidgets('5. Customs terminal displays traveler request prompt with quotes',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.text('"I need to board the train to Tokyo Station."'), findsOneWidget);
      expect(find.text('TRAVELER REQUEST'), findsOneWidget);
    });

    testWidgets('6. Customs terminal renders traveler voice icon',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.byIcon(Icons.record_voice_over_rounded), findsOneWidget);
    });

    testWidgets('7. Initial layout renders TravelDeskPassportBook',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.byType(TravelDeskPassportBook), findsOneWidget);
      expect(find.byKey(const Key('travel_desk_passport_book')), findsOneWidget);
    });

    testWidgets('8. Passport book renders custom travelDocument header and menu book icon',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.text('JAPAN RAIL PASS BOOKLET'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 2. Passport Book Booklet Pages & Display (Tests 9-15)
    // -------------------------------------------------------------------------

    testWidgets('9. Renders horizontal booklet pages matching options count (3 destinations)',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      for (int i = 0; i < 3; i++) {
        expect(find.byKey(Key('travel_desk_page_$i')), findsOneWidget);
      }
    });

    testWidgets('10. Destination pages display option text in uppercase',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.text('TOKYO EXPRESS'), findsOneWidget);
      expect(find.text('KYOTO SHINKANSEN'), findsOneWidget);
      expect(find.text('OSAKA METRO'), findsOneWidget);
    });

    testWidgets('11. Destination pages display formatted page numbers',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.text('PAGE 01'), findsOneWidget);
      expect(find.text('PAGE 02'), findsOneWidget);
      expect(find.text('PAGE 03'), findsOneWidget);
    });

    testWidgets('12. Destination pages render globe icons',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.byIcon(Icons.public_rounded), findsNWidgets(3));
    });

    testWidgets('13. Drag target pages render CustomPaint with PassportBackgroundGrid',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      final gridPainters = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      final hasGrid = gridPainters.any((cp) => cp.painter is PassportBackgroundGrid);
      expect(hasGrid, isTrue);
    });

    testWidgets('14. Unselected destination pages display neutral border decoration',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const Key('travel_desk_page_0')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final boxDeco = container.decoration as BoxDecoration;
      expect(boxDeco.borderRadius, BorderRadius.circular(18.r));
    });

    testWidgets('15. Destination pages expose accessibility semantics with page label',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      final semantics = find.byWidgetPredicate((w) =>
          w is Semantics &&
          (w.properties.label?.contains('Passport page 1, TOKYO EXPRESS') ?? false));
      expect(semantics, findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 3. Stamp Station & Mechanical Draggable (Tests 16-22)
    // -------------------------------------------------------------------------

    testWidgets('16. Initial layout renders TravelDeskStampStation',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.byType(TravelDeskStampStation), findsOneWidget);
      expect(find.byKey(const Key('travel_desk_stamp_station')), findsOneWidget);
    });

    testWidgets('17. Stamp station renders "TRAVEL DESK STAMP" header and touch icon',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.text('TRAVEL DESK STAMP'), findsOneWidget);
      expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
    });

    testWidgets('18. Stamp station renders drag prompt instruction label',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.text('DRAG STAMP TO MATCHING DESTINATION'), findsOneWidget);
    });

    testWidgets('19. Stamp station renders Draggable<int> widget with payload 99',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      final draggable = tester.widget<Draggable<int>>(find.byType(Draggable<int>));
      expect(draggable.data, 99);
    });

    testWidgets('20. Stamp core renders mechanical visa approval icon',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.byIcon(Icons.approval_rounded), findsOneWidget);
    });

    testWidgets('21. Stamp core renders lower metallic base plate indicator',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      final basePlate = find.byWidgetPredicate((w) =>
          w is Container &&
          w.constraints?.minWidth == 86.w &&
          w.constraints?.minHeight == 10.h);
      expect(basePlate, findsOneWidget);
    });

    testWidgets('22. Mechanical stamp draggable exposes accessibility semantics',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      final semantics = find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.button == true &&
          w.properties.label == 'Mechanical visa stamp');
      expect(semantics, findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 4. Interaction & Stamping Mechanics (Tests 23-30)
    // -------------------------------------------------------------------------

    testWidgets('23. Drag start triggers selection haptic and hint sound',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      clearInteractions(mockHapticService);
      clearInteractions(mockSoundService);

      final draggable = tester.widget<Draggable<int>>(find.byType(Draggable<int>));
      draggable.onDragStarted?.call();
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playHint()).called(1);
    });

    testWidgets('24. Drag end resets hovered index',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      final draggable = tester.widget<Draggable<int>>(find.byType(Draggable<int>));
      draggable.onDragEnd?.call(DraggableDetails(
        wasAccepted: false,
        velocity: Velocity.zero,
        offset: Offset.zero,
      ));
      await tester.pump();

      final book = tester.widget<TravelDeskPassportBook>(find.byType(TravelDeskPassportBook));
      expect(book.hoveredIndex, isNull);
    });

    testWidgets('25. DragTarget onMove triggers onHoverChanged with selection haptic',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      clearInteractions(mockHapticService);

      final dragTarget = tester.widget<DragTarget<int>>(
        find.descendant(
          of: find.byKey(const Key('travel_desk_page_1')),
          matching: find.byType(DragTarget<int>),
        ),
      );
      dragTarget.onMove?.call(DragTargetDetails<int>(data: 99, offset: Offset.zero));
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      final book = tester.widget<TravelDeskPassportBook>(find.byType(TravelDeskPassportBook));
      expect(book.hoveredIndex, 1);
    });

    testWidgets('26. DragTarget onLeave resets hoveredIndex',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      final dragTarget = tester.widget<DragTarget<int>>(
        find.descendant(
          of: find.byKey(const Key('travel_desk_page_1')),
          matching: find.byType(DragTarget<int>),
        ),
      );
      dragTarget.onLeave?.call(99);
      await tester.pump();

      final book = tester.widget<TravelDeskPassportBook>(find.byType(TravelDeskPassportBook));
      expect(book.hoveredIndex, isNull);
    });

    testWidgets('27. Direct tap on destination page calls _submitStamp',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      clearInteractions(mockRoleplayBloc);

      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>()))).called(1);
    });

    testWidgets('28. Incorrect stamp submission triggers wrong answer with userAnswer',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      clearInteractions(mockRoleplayBloc);

      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('29. Incorrect stamp displays "DENIED" stamp mark badge in red',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('DENIED'), findsOneWidget);
    });

    testWidgets('30. Incorrect stamp does NOT mount SpeakToConfirmOverlay',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 5. Phase 2 Verbal Confirmation & Evaluation (Tests 31-38)
    // -------------------------------------------------------------------------

    testWidgets('31. Correct destination stamp triggers selection haptic',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      clearInteractions(mockHapticService);

      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('32. Correct destination stamp displays "APPROVED" stamp mark badge in green',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('APPROVED'), findsOneWidget);
    });

    testWidgets('33. Correct destination stamp advances to Phase 2 SpeakToConfirmOverlay without early BLoC submission',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      clearInteractions(mockRoleplayBloc);

      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('34. SpeakToConfirmOverlay displays expectedText matching chosen correct destination',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      expect(overlay.expectedText, 'Tokyo Express');
    });

    testWidgets('35. Stamp station hides during Phase 2',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('travel_desk_stamp_station')), findsNothing);
    });

    testWidgets('36. SpeakToConfirmOverlay "Nailed It" dispatches RoleplaySpeakConfirmed(5) bonus coins',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockRoleplayBloc);
      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(const RoleplaySpeakConfirmed(5))).called(1);
    });

    testWidgets('37. SpeakToConfirmOverlay "Nailed It" dispatches SubmitAnswer(true) with success audio & haptic',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockRoleplayBloc);
      clearInteractions(mockSoundService);
      clearInteractions(mockHapticService);

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('38. SpeakToConfirmOverlay "Needs Work" dispatches SubmitAnswer(false) with error audio & haptic',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockRoleplayBloc);
      clearInteractions(mockSoundService);
      clearInteractions(mockHapticService);

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    // -------------------------------------------------------------------------
    // 6. Answered States & Bottom Sheet Feedback (Tests 39-44)
    // -------------------------------------------------------------------------

    testWidgets('39. Answer lockout prevents secondary stamp taps once answered',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockRoleplayBloc);
      await tester.tap(find.byKey(const Key('travel_desk_page_2')), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockRoleplayBloc.add(any()));
    });

    testWidgets('40. Answered state unmounts SpeakToConfirmOverlay',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('41. Answered state renders GameFeedbackCard in bottom sheet',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('42. Tapping action button in GameFeedbackCard dispatches NextQuestion()',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockRoleplayBloc);
      final actionBtn = find.text('TRY AGAIN');
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('43. Answered state renders CustomPaint with StampRipplePainter',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      final hasRipple = paints.any((p) => p.painter is StampRipplePainter);
      expect(hasRipple, isTrue);
    });

    testWidgets('44. DragTarget rejects drops when already answered',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final dragTarget = tester.widget<DragTarget<int>>(
        find.descendant(
          of: find.byKey(const Key('travel_desk_page_0')),
          matching: find.byType(DragTarget<int>),
        ),
      );
      final willAccept = dragTarget.onWillAcceptWithDetails?.call(
        DragTargetDetails<int>(data: 99, offset: Offset.zero),
      );
      expect(willAccept, isFalse);
    });

    // -------------------------------------------------------------------------
    // 7. State Transitions & Edge Cases (Tests 45-50)
    // -------------------------------------------------------------------------

    testWidgets('45. State transition to question 2 updates prompt and destination pages',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      expect(find.text('"I need to board the train to Tokyo Station."'), findsOneWidget);

      final nextState = testLoadedState.copyWith(currentIndex: 1);
      roleplayStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        find.text('"Excuse me, which flight heads directly to London Heathrow?"'),
        findsOneWidget,
      );
      expect(find.text('FLIGHT BA-142'), findsOneWidget);
    });

    testWidgets('46. State transition clears previous selection and hovered state',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      await tester.tap(find.byKey(const Key('travel_desk_page_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('DENIED'), findsOneWidget);

      final nextState = testLoadedState.copyWith(currentIndex: 1);
      roleplayStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('DENIED'), findsNothing);
      expect(find.text('APPROVED'), findsNothing);
    });

    testWidgets('47. Quest with itinerary property renders itinerary list instead of options',
        (tester) async {
      final itineraryQuest = createQuest(
        options: const ['Old 1', 'Old 2'],
        itinerary: const ['Itinerary Port A', 'Itinerary Port B', 'Itinerary Port C'],
        correctAnswerIndex: 1,
        correctAnswer: 'Itinerary Port B',
      );
      final state = testLoadedState.copyWith(quests: [itineraryQuest]);
      await pumpTravelDeskScreen(tester, state: state);

      expect(find.text('ITINERARY PORT A'), findsOneWidget);
      expect(find.text('ITINERARY PORT B'), findsOneWidget);
      expect(find.text('ITINERARY PORT C'), findsOneWidget);
      expect(find.text('OLD 1'), findsNothing);
    });

    testWidgets('48. Custom travelDocument displays in passport booklet header',
        (tester) async {
      final customDocQuest = createQuest(travelDocuments: 'GALACTIC VISA ENTRY FOLIO');
      final state = testLoadedState.copyWith(quests: [customDocQuest]);
      await pumpTravelDeskScreen(tester, state: state);

      expect(find.text('GALACTIC VISA ENTRY FOLIO'), findsOneWidget);
    });

    testWidgets('49. Single option quest renders single destination page cleanly',
        (tester) async {
      final singleQuest = createQuest(
        options: const ['Direct Shuttle'],
        correctAnswerIndex: 0,
        correctAnswer: 'Direct Shuttle',
      );
      final state = testLoadedState.copyWith(quests: [singleQuest]);
      await pumpTravelDeskScreen(tester, state: state);

      expect(find.text('DIRECT SHUTTLE'), findsOneWidget);
      expect(find.byKey(const Key('travel_desk_page_0')), findsOneWidget);
      expect(find.byKey(const Key('travel_desk_page_1')), findsNothing);
    });

    testWidgets('50. Two-option quest renders two destination pages cleanly',
        (tester) async {
      final twoQuest = createQuest(
        options: const ['Option A', 'Option B'],
        correctAnswerIndex: 0,
        correctAnswer: 'Option A',
      );
      final state = testLoadedState.copyWith(quests: [twoQuest]);
      await pumpTravelDeskScreen(tester, state: state);

      expect(find.text('OPTION A'), findsOneWidget);
      expect(find.text('OPTION B'), findsOneWidget);
      expect(find.byKey(const Key('travel_desk_page_2')), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 8. Header, Overlays, Themes & Viewports (Tests 51-55)
    // -------------------------------------------------------------------------

    testWidgets('51. Tapping hint button in header dispatches RoleplayHintUsed',
        (tester) async {
      await pumpTravelDeskScreen(tester);
      clearInteractions(mockRoleplayBloc);

      await tester.tap(find.byIcon(Icons.lightbulb_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>()))).called(1);
    });

    testWidgets('52. Level 1 displays QuestBriefingOverlay with "GLOBAL TRAVELER"',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpTravelDeskScreen(tester, level: 1);

      expect(find.byType(QuestBriefingOverlay), findsOneWidget);
      expect(find.text('GLOBAL TRAVELER'), findsOneWidget);
      expect(find.text('START JOURNEY'), findsOneWidget);

      await tester.tap(find.text('START JOURNEY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });

    testWidgets('53. Uninitialized initial state renders GameShimmerLoading',
        (tester) async {
      await pumpTravelDeskScreen(tester, state: const RoleplayInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('54. Game over state with 0 lives renders cleanly',
        (tester) async {
      final gameOverState = RoleplayGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.travelDesk,
        level: 2,
      );
      await pumpTravelDeskScreen(tester, state: gameOverState);
      expect(find.byType(TravelDeskScreen), findsOneWidget);
    });

    testWidgets('55. Light theme renders cleanly with light mode styling',
        (tester) async {
      await pumpTravelDeskScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(TravelDeskScreen), findsOneWidget);
      expect(find.text('TOKYO EXPRESS'), findsOneWidget);
    });

    testWidgets('56. Compact mobile (320x568) and tablet (768x1024) render with zero overflow',
        (tester) async {
      await pumpTravelDeskScreen(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);

      await pumpTravelDeskScreen(tester, size: const Size(768, 1024));
      expect(tester.takeException(), isNull);
    });
  });
}

