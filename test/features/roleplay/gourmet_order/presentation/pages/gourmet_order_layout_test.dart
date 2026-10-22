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
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
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
import 'package:vowl/features/roleplay/gourmet_order/presentation/pages/gourmet_order_screen.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_banquet_header.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_table_setting.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_plate_tray.dart';

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

class FakeRoleplayEvent extends Fake implements RoleplayEvent {}

class FakeRoleplayState extends Fake implements RoleplayState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  const sampleQuest1 = RoleplayQuest(
    id: 'go_1',
    instruction:
        'Select and load the requested dishes onto the serving platter.',
    difficulty: 1,
    subtype: GameSubtype.gourmetOrder,
    prompt:
        'Prepare a three-course French banquet starting with Truffle Soup and finishing with Creme Brulee.',
    options: ['Truffle Soup', 'Roast Duck', 'Creme Brulee', 'Garlic Bread'],
    menuPrices: [r'$18.00', r'$32.00', r'$14.00', r'$8.00'],
    correctAnswer: 'Truffle Soup, Roast Duck, Creme Brulee',
    hint: 'A three-course meal includes soup, main, and dessert.',
    explanation: 'The French three-course banquet is properly sequenced.',
  );

  const sampleQuest2 = RoleplayQuest(
    id: 'go_2',
    instruction: 'Assemble the Italian tasting menu order.',
    difficulty: 2,
    subtype: GameSubtype.gourmetOrder,
    prompt: 'Order the Bruschetta appetizer and Osso Buco main course.',
    options: ['Bruschetta', 'Osso Buco', 'Tiramisu', 'Minestrone'],
    menuPrices: [r'$12.00', r'$38.00', r'$11.00', r'$10.00'],
    correctAnswer: 'Bruschetta, Osso Buco',
    hint: 'Only two courses were requested.',
    explanation: 'Appetizer and main course make up the two-course order.',
  );

  final testLoadedState = RoleplayLoaded(
    quests: const [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.gourmetOrder,
    level: 2,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeRoleplayEvent());
    registerFallbackValue(FakeRoleplayState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const RoleplayHintUsed());
    registerFallbackValue(const RoleplaySpeakConfirmed(5));
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  setUp(() async {
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
    when(
      () => mockRoleplayBloc.stream,
    ).thenAnswer((_) => roleplayStreamController.stream);
    when(() => mockRoleplayBloc.state).thenReturn(testLoadedState);

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

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.startRecording(),
    ).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/tmp/gourmet_order_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    VowlMotion.lowAnimationModeOverride.value = true;

    when(
      () => mockLocaleService.tr(
        any(),
        args: any(named: 'args'),
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((invocation) {
      final fallback =
          invocation.namedArguments[const Symbol('fallback')] as String?;
      final key = invocation.positionalArguments[0] as String;
      return fallback ?? key;
    });

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockAnalyticsService.logSelfEvaluation(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAnalyticsService.logGameSkipped(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAnalyticsService.logPurchaseAttempt(any()),
    ).thenAnswer((_) async {});

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_gourmetOrder': true,
    });

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
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

  tearDown(() async {
    await roleplayStreamController.close();
  });

  Future<void> pumpGourmetOrderScreen(
    WidgetTester tester, {
    RoleplayState? state,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 1400),
    int level = 2,
    bool reduceMotion = true,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final resolvedState = state ?? testLoadedState;
    when(() => mockRoleplayBloc.state).thenReturn(resolvedState);
    if (!roleplayStreamController.isClosed) {
      roleplayStreamController.add(resolvedState);
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
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: GourmetOrderScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder findPlate(int index) => find.byKey(Key('gourmet_order_plate_$index'));
  Finder findPlatePrice(String item) =>
      find.byKey(Key('gourmet_order_plate_price_$item'));
  Finder findPlateCheck(String item) =>
      find.byKey(Key('gourmet_order_plate_check_$item'));

  group('GourmetOrderScreen Layout & Rendering Hierarchy', () {
    testWidgets('1. renders GourmetOrderBanquetHeader on screen', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      expect(find.byType(GourmetOrderBanquetHeader), findsOneWidget);
      expect(
        find.byKey(const Key('gourmet_order_banquet_header')),
        findsOneWidget,
      );
    });

    testWidgets('2. renders GourmetOrderTableSetting cloche platter', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      expect(find.byType(GourmetOrderTableSetting), findsOneWidget);
      expect(
        find.byKey(const Key('gourmet_order_table_setting')),
        findsOneWidget,
      );
    });

    testWidgets('3. renders GourmetOrderPlateTray with plates', (tester) async {
      await pumpGourmetOrderScreen(tester);
      expect(find.byType(GourmetOrderPlateTray), findsOneWidget);
      expect(find.byKey(const Key('gourmet_order_plate_tray')), findsOneWidget);
    });

    testWidgets(
      '4. action buttons are initially hidden when platter is empty',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        expect(
          find.byKey(const Key('gourmet_order_serve_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('gourmet_order_clear_button')),
          findsNothing,
        );
      },
    );

    testWidgets('5. renders app bar with GameProgressHeader and lives', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      expect(find.byType(GameProgressHeader), findsOneWidget);
      expect(find.byType(QuestHintButton), findsOneWidget);
    });
  });

  group('Banquet Header Component Tests', () {
    testWidgets('6. displays client request label and room service icon', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      expect(
        find.byKey(const Key('gourmet_order_banquet_client_request_label')),
        findsOneWidget,
      );
      expect(find.text('CUSTOMER ORDER'), findsOneWidget);
      expect(find.byIcon(Icons.room_service_rounded), findsOneWidget);
    });

    testWidgets('7. displays prompt text correctly', (tester) async {
      await pumpGourmetOrderScreen(tester);
      expect(
        find.byKey(const Key('gourmet_order_banquet_prompt_text')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Prepare a three-course French banquet'),
        findsOneWidget,
      );
    });

    testWidgets('8. displays instruction banner and info icon', (tester) async {
      await pumpGourmetOrderScreen(tester);
      expect(
        find.byKey(const Key('gourmet_order_banquet_instruction_text')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Select and load the requested dishes'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GourmetOrderBanquetHeader),
          matching: find.byIcon(Icons.info_outline_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('9. header renders cleanly when instruction is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: GourmetOrderBanquetHeader(
                prompt: 'Order some soup.',
                instruction: null,
                color: Colors.blue,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const Key('gourmet_order_banquet_prompt_text')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('gourmet_order_banquet_instruction_text')),
        findsNothing,
      );
    });
  });

  group('Table Setting / Platter Display Tests', () {
    testWidgets('10. initial platter shows cloche icon', (tester) async {
      await pumpGourmetOrderScreen(tester);
      expect(
        find.byKey(const Key('gourmet_order_table_cloche_icon')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.room_service_outlined), findsOneWidget);
    });

    testWidgets('11. initial status text displays ORDER PLATTER', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      expect(
        find.byKey(const Key('gourmet_order_table_status_text')),
        findsOneWidget,
      );
      expect(find.text('ORDER PLATTER'), findsOneWidget);
    });

    testWidgets(
      '12. loaded plates count badge is hidden when no items selected',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        expect(
          find.byKey(const Key('gourmet_order_table_loaded_badge')),
          findsNothing,
        );
      },
    );

    testWidgets('13. drag target widget is active and ready', (tester) async {
      await pumpGourmetOrderScreen(tester);
      expect(
        find.byKey(const Key('gourmet_order_table_drag_target')),
        findsOneWidget,
      );
    });

    testWidgets('14. platter container has circular decoration', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      final container = tester.widget<AnimatedContainer>(
        find.byKey(const Key('gourmet_order_table_container')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });
  });

  group('Plate Tray & Options Display Tests', () {
    testWidgets('15. displays plate tray title and restaurant icon', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      expect(
        find.byKey(const Key('gourmet_order_plate_tray_title')),
        findsOneWidget,
      );
      expect(find.text('MENU OPTIONS'), findsOneWidget);
      expect(
        find.byKey(const Key('gourmet_order_plate_tray_icon')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('16. renders all 4 plate options', (tester) async {
      await pumpGourmetOrderScreen(tester);
      expect(findPlate(0), findsOneWidget);
      expect(findPlate(1), findsOneWidget);
      expect(findPlate(2), findsOneWidget);
      expect(findPlate(3), findsOneWidget);
      expect(findPlate(4), findsNothing);
    });

    testWidgets('17. displays dish names in uppercase', (tester) async {
      await pumpGourmetOrderScreen(tester);
      expect(find.text('TRUFFLE SOUP'), findsOneWidget);
      expect(find.text('ROAST DUCK'), findsOneWidget);
      expect(find.text('CREME BRULEE'), findsOneWidget);
      expect(find.text('GARLIC BREAD'), findsOneWidget);
    });

    testWidgets('18. displays dish menu prices correctly', (tester) async {
      await pumpGourmetOrderScreen(tester);
      expect(findPlatePrice('Truffle Soup'), findsOneWidget);
      expect(find.text(r'$18.00'), findsOneWidget);
      expect(find.text(r'$32.00'), findsOneWidget);
      expect(find.text(r'$14.00'), findsOneWidget);
      expect(find.text(r'$8.00'), findsOneWidget);
    });

    testWidgets(
      '19. fallback price (\$3.50) is used when menuPrices is shorter',
      (tester) async {
        const questShortPrices = RoleplayQuest(
          id: 'go_short_prices',
          instruction: 'Pick items',
          difficulty: 1,
          subtype: GameSubtype.gourmetOrder,
          prompt: 'Order specials',
          options: ['Item A', 'Item B'],
          menuPrices: [r'$10.00'],
          correctAnswer: 'Item A',
        );
        final state = testLoadedState.copyWith(quests: [questShortPrices]);
        await pumpGourmetOrderScreen(tester, state: state);
        expect(find.text(r'$10.00'), findsOneWidget);
        expect(find.text(r'$3.50'), findsOneWidget);
      },
    );
  });

  group('Plate Selection Mechanics Tests', () {
    testWidgets(
      '20. tapping an unselected plate triggers haptic and synth hint sound',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.selection()).called(1);
        verify(() => mockSoundService.playHint()).called(1);
      },
    );

    testWidgets(
      '21. tapping a plate adds it to selection and reveals checkmark',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        expect(findPlateCheck('Truffle Soup'), findsNothing);

        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(findPlateCheck('Truffle Soup'), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '22. tapping plate reveals loaded count badge (1 DISH SELECTED)',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byKey(const Key('gourmet_order_table_loaded_badge')),
          findsOneWidget,
        );
        expect(find.text('1 DISH SELECTED'), findsOneWidget);
      },
    );

    testWidgets('23. selecting multiple plates increments loaded badge count', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findPlate(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('2 DISHES SELECTED'), findsOneWidget);
      expect(findPlateCheck('Truffle Soup'), findsOneWidget);
      expect(findPlateCheck('Roast Duck'), findsOneWidget);
    });

    testWidgets('24. tapping a selected plate deselects it and updates count', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1 DISH SELECTED'), findsOneWidget);

      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(findPlateCheck('Truffle Soup'), findsNothing);
      expect(
        find.byKey(const Key('gourmet_order_table_loaded_badge')),
        findsNothing,
      );
    });

    testWidgets(
      '25. action buttons appear when at least one plate is selected',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        expect(
          find.byKey(const Key('gourmet_order_serve_button')),
          findsNothing,
        );

        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byKey(const Key('gourmet_order_serve_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('gourmet_order_clear_button')),
          findsOneWidget,
        );
        expect(find.text('SERVE ORDER'), findsOneWidget);
        expect(find.text('CLEAR SELECTION'), findsOneWidget);
      },
    );

    testWidgets('26. deselecting the only plate hides action buttons again', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const Key('gourmet_order_serve_button')),
        findsOneWidget,
      );

      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('gourmet_order_serve_button')), findsNothing);
    });
  });

  group('Clear Platter Button Tests', () {
    testWidgets(
      '27. tapping CLEAR SELECTION empties selection and hides buttons',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('2 DISHES SELECTED'), findsOneWidget);

        await tester.tap(find.byKey(const Key('gourmet_order_clear_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byKey(const Key('gourmet_order_table_loaded_badge')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('gourmet_order_serve_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('gourmet_order_clear_button')),
          findsNothing,
        );
        expect(findPlateCheck('Truffle Soup'), findsNothing);
        expect(findPlateCheck('Roast Duck'), findsNothing);
      },
    );

    testWidgets('28. CLEAR SELECTION triggers selection haptic feedback', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      clearInteractions(mockHapticService);

      await tester.tap(find.byKey(const Key('gourmet_order_clear_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
    });
  });

  group('Drag and Drop Mechanics Tests', () {
    testWidgets(
      '29. dragging plate and dropping on table setting adds to selection',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        expect(find.text('1 PLATES LOADED'), findsNothing);

        final plateCenter = tester.getCenter(findPlate(0));
        final targetCenter = tester.getCenter(
          find.byKey(const Key('gourmet_order_table_drag_target')),
        );

        final gesture = await tester.startGesture(plateCenter);
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveTo(targetCenter);
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(findPlateCheck('Truffle Soup'), findsOneWidget);
        expect(find.text('1 DISH SELECTED'), findsOneWidget);
      },
    );

    testWidgets(
      '30. dropping an already selected plate does not duplicate it',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('1 DISH SELECTED'), findsOneWidget);

        final plateCenter = tester.getCenter(findPlate(0));
        final targetCenter = tester.getCenter(
          find.byKey(const Key('gourmet_order_table_drag_target')),
        );

        final gesture = await tester.startGesture(plateCenter);
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveTo(targetCenter);
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('1 DISH SELECTED'), findsOneWidget);
      },
    );
  });

  group('Submission & Phase 2 Transition Tests', () {
    testWidgets(
      '31. tapping SERVE ORDER with incorrect items fails with error sound & haptic',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        // Only select Truffle Soup and Garlic Bread (wrong combination)
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(3));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
        verify(
          () => mockRoleplayBloc.add(
            any(
              that: isA<SubmitAnswer>().having(
                (e) => e.isCorrect,
                'isCorrect',
                false,
              ),
            ),
          ),
        ).called(1);
        // SpeakToConfirmOverlay must NOT be mounted on wrong answer
        expect(
          find.byKey(const Key('gourmet_order_speak_overlay')),
          findsNothing,
        );
      },
    );

    testWidgets(
      '32. incorrect platter updates table setting status to INCORRECT ORDER',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('INCORRECT ORDER'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '33. tapping SERVE ORDER with correct items transitions to Phase 2 SpeakToConfirmOverlay',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        // Correct items: Truffle Soup, Roast Duck, Creme Brulee
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // SubmitAnswer should NOT have been sent yet (we wait for Phase 2 speech)
        verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));

        // SpeakToConfirmOverlay should now be mounted
        expect(
          find.byKey(const Key('gourmet_order_speak_overlay')),
          findsOneWidget,
        );
        expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      },
    );

    testWidgets('34. SpeakToConfirmOverlay displays expectedText', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findPlate(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findPlate(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('gourmet_order_speak_overlay')),
      );
      expect(overlay.expectedText, 'Truffle Soup, Roast Duck, Creme Brulee');

      // Verify SpeakToConfirmOverlay is padded properly and does not touch screen edges
      final paddingFinder = find.ancestor(
        of: find.byKey(const Key('gourmet_order_speak_overlay')),
        matching: find.byType(Padding),
      );
      expect(paddingFinder, findsWidgets);
      final paddingWidget = tester.widget<Padding>(paddingFinder.first);
      final insets = paddingWidget.padding as EdgeInsets;
      expect(insets.left, greaterThanOrEqualTo(16.0));
      expect(insets.right, greaterThanOrEqualTo(16.0));
    });

    testWidgets('35. action buttons are hidden during Phase 2 overlay', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findPlate(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findPlate(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('gourmet_order_serve_button')), findsNothing);
      expect(find.byKey(const Key('gourmet_order_clear_button')), findsNothing);
    });
  });

  group('Phase 2 Evaluation & Confirmation Tests', () {
    testWidgets(
      '36. tapping Nailed It dispatches RoleplaySpeakConfirmed and SubmitAnswer(true)',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Scroll to bring SpeakToConfirmOverlay into view
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -600),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Switch to manual evaluation in SttAutoPassWrapper
        final manualBtn = find.text('Evaluate myself manually');
        expect(manualBtn, findsOneWidget);
        await tester.tap(manualBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Record audio via speaking mic button to reveal eval controls
        final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
        expect(micBtn, findsOneWidget);
        await tester.tap(micBtn);
        await tester.pump();
        await tester.runAsync(
          () async => await Future.delayed(const Duration(milliseconds: 600)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(micBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Scroll slightly more so Nailed It is visible
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -300),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Find Nailed It button inside SpeakToConfirmOverlay
        final nailedItFinder = find.text('Nailed It');
        expect(nailedItFinder, findsOneWidget);
        await tester.tap(nailedItFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => mockRoleplayBloc.add(const RoleplaySpeakConfirmed(5)),
        ).called(1);
        verify(
          () => mockRoleplayBloc.add(
            any(
              that: isA<SubmitAnswer>().having(
                (e) => e.isCorrect,
                'isCorrect',
                true,
              ),
            ),
          ),
        ).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
      },
    );

    testWidgets(
      '37. tapping Needs Work calls submitWrongAnswer and SubmitAnswer(false)',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Scroll to bring SpeakToConfirmOverlay into view
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -600),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Switch to manual evaluation in SttAutoPassWrapper
        final manualBtn = find.text('Evaluate myself manually');
        expect(manualBtn, findsOneWidget);
        await tester.tap(manualBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
        expect(micBtn, findsOneWidget);
        await tester.tap(micBtn);
        await tester.pump();
        await tester.runAsync(
          () async => await Future.delayed(const Duration(milliseconds: 600)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(micBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Scroll slightly more so Needs Work is visible
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -300),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final needsWorkFinder = find.text('Needs Work');
        expect(needsWorkFinder, findsOneWidget);
        await tester.tap(needsWorkFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => mockRoleplayBloc.add(
            any(
              that: isA<SubmitAnswer>().having(
                (e) => e.isCorrect,
                'isCorrect',
                false,
              ),
            ),
          ),
        ).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
      },
    );

    testWidgets(
      '38. correct completion updates table setting to SERVED PERFECTLY',
      (tester) async {
        await pumpGourmetOrderScreen(tester);
        await tester.tap(findPlate(0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(findPlate(2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Scroll to bring SpeakToConfirmOverlay into view
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -600),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Switch to manual evaluation in SttAutoPassWrapper
        final manualBtn = find.text('Evaluate myself manually');
        expect(manualBtn, findsOneWidget);
        await tester.tap(manualBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
        expect(micBtn, findsOneWidget);
        await tester.tap(micBtn);
        await tester.pump();
        await tester.runAsync(
          () async => await Future.delayed(const Duration(milliseconds: 600)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(micBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Scroll slightly more so Nailed It is visible
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -300),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('Nailed It'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('ORDER COMPLETE'), findsOneWidget);
        expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
      },
    );
  });

  group('Answer Lockout & Navigation Tests', () {
    testWidgets('39. once answered, tapping plates does not change selection', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      await tester.tap(findPlate(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Submit incorrect to enter answered state
      await tester.tap(find.byKey(const Key('gourmet_order_serve_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Attempt to tap another plate
      await tester.tap(findPlate(3), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Checkmark on plate 3 must NOT appear
      expect(findPlateCheck('Garlic Bread'), findsNothing);
    });

    testWidgets('40. once answered, bottom bar renders CONTINUE button', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('41. tapping CONTINUE dispatches NextQuestion event', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(
        () => mockRoleplayBloc.add(any(that: isA<NextQuestion>())),
      ).called(1);
    });
  });

  group('Hint, Lifecycle & Briefing Tests', () {
    testWidgets('42. tapping hint button dispatches RoleplayHintUsed', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester);
      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(
        () => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>())),
      ).called(1);
    });

    testWidgets('43. Level 1 displays GameBriefingLayer with Order Master', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_gourmetOrder': false,
      });

      await pumpGourmetOrderScreen(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('ORDER MASTER'), findsOneWidget);
      expect(find.text('PLACE ORDER'), findsOneWidget);

      await tester.tap(find.text('PLACE ORDER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets(
      '44. GameShimmerLoading renders when state is RoleplayInitial',
      (tester) async {
        await pumpGourmetOrderScreen(tester, state: const RoleplayInitial());
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(GourmetOrderBanquetHeader), findsNothing);
      },
    );

    testWidgets('45. Game over state renders cleanly without error', (
      tester,
    ) async {
      const gameOverState = RoleplayGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.gourmetOrder,
        level: 2,
      );
      await pumpGourmetOrderScreen(tester, state: gameOverState);
      expect(find.byType(GourmetOrderScreen), findsOneWidget);
    });
  });

  group('Themes, Responsiveness & Motion Tests', () {
    testWidgets('46. renders cleanly in light theme mode', (tester) async {
      await pumpGourmetOrderScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(GourmetOrderBanquetHeader), findsOneWidget);
      expect(find.byType(GourmetOrderTableSetting), findsOneWidget);
      expect(find.byType(GourmetOrderPlateTray), findsOneWidget);
    });

    testWidgets('47. renders cleanly in dark theme mode', (tester) async {
      await pumpGourmetOrderScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(GourmetOrderBanquetHeader), findsOneWidget);
      expect(find.byType(GourmetOrderTableSetting), findsOneWidget);
      expect(find.byType(GourmetOrderPlateTray), findsOneWidget);
    });

    testWidgets('48. renders on compact mobile (320x568) with zero overflow', (
      tester,
    ) async {
      await pumpGourmetOrderScreen(tester, size: const Size(320, 568));
      expect(find.byType(GourmetOrderBanquetHeader), findsOneWidget);
      expect(find.byType(GourmetOrderTableSetting), findsOneWidget);
      expect(find.byType(GourmetOrderPlateTray), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '49. reduceMotion suppresses repeating animations without errors',
      (tester) async {
        await pumpGourmetOrderScreen(tester, reduceMotion: true);
        expect(find.byType(GourmetOrderBanquetHeader), findsOneWidget);
        expect(find.byType(GourmetOrderTableSetting), findsOneWidget);
        expect(find.byType(GourmetOrderPlateTray), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
