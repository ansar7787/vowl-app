import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/cloze_test/presentation/pages/cloze_test_screen.dart';
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_pneumatic_port.dart';
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_fuel_cells.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/dynamic_anagram_wrapper.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class MockReadingBloc extends Mock implements ReadingBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockEconomyBloc extends Mock implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}
class MockTtsService extends Mock implements TtsService {}
class MockLocaleService extends Mock implements LocaleService {}
class MockAppLogger extends Mock implements AppLogger {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAdService extends Mock implements AdService {}

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
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  setUpAll(() {
    registerFallbackValue(FakeReadingEvent());
    registerFallbackValue(FakeReadingState());
    registerFallbackValue(const SubmitAnswer(true));
  });

  const testClozeQuest = ReadingQuest(
    id: 'RDG_CLOZETEST_L1_Q1',
    instruction: 'Select the option that fits the context.',
    difficulty: 1,
    subtype: GameSubtype.clozeTest,
    passage: "Please close the ____ — it's cold outside.",
    options: ['window', 'road', 'shelf', 'river'],
    correctAnswer: 'window',
    targetWord: 'window',
    wordCategory: 'noun',
    hint: 'Think of the glass part of a room that can be opened or shut.',
    explanation: 'A window can be opened or closed, and closing it keeps cold air out.',
  );

  const testLoadedState = ReadingLoaded(
    quests: [testClozeQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({});

    mockReadingBloc = MockReadingBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

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
          displayName: 'Word Explorer',
          vowlMascot: 'vowl_prime',
          completedLevels: {},
          totalExp: 200,
          isPremium: true,
          hintCount: 3,
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
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});

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

    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
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
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpClozeTest(
    WidgetTester tester, {
    ReadingState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
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
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: Scaffold(
              body: ClozeTestScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ClozeTestScreen - Production Layout & Mechanics Tests', () {
    testWidgets('1. Initial rendering of instruction, pneumatic port passage, and fuel cell options',
        (tester) async {
      await pumpClozeTest(tester);

      // Verify instruction pill
      expect(
        find.textContaining('fits the context'),
        findsOneWidget,
      );

      // Verify pneumatic port passage text and placeholder
      expect(find.byType(ClozeTestPneumaticPort), findsOneWidget);
      expect(find.text('DRAG HERE'), findsOneWidget);
      expect(find.text('(noun)'), findsOneWidget);

      // Verify fuel cell options
      expect(find.byType(ClozeTestFuelCells), findsOneWidget);
      expect(find.text('WINDOW'), findsOneWidget);
      expect(find.text('ROAD'), findsOneWidget);
      expect(find.text('SHELF'), findsOneWidget);
      expect(find.text('RIVER'), findsOneWidget);
    });

    testWidgets('2. Tapping wrong fuel cell option docks it, triggers wrong audio/haptics, and dispatches SubmitAnswer(false)',
        (tester) async {
      await pumpClozeTest(tester);

      // Tap on incorrect option "ROAD"
      final wrongOption = find.text('ROAD');
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify wrong feedback
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('3. Tapping correct fuel cell option docks it, triggers selection haptics, and reveals DynamicAnagramWrapper',
        (tester) async {
      await pumpClozeTest(tester);

      // Tap on correct option "WINDOW"
      final correctOption = find.text('WINDOW');
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify selection haptic was triggered
      verify(() => mockHapticService.selection()).called(1);

      // Verify DynamicAnagramWrapper is revealed
      expect(find.byType(DynamicAnagramWrapper), findsOneWidget);
    });

    testWidgets('4. Skipping DynamicAnagramWrapper dispatches SubmitAnswer(true)',
        (tester) async {
      await pumpClozeTest(tester);

      // Tap on correct option "WINDOW" to reveal anagram
      await tester.tap(find.text('WINDOW'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Locate Skip button in DynamicAnagramWrapper and tap it
      final skipBtn = find.text('SKIP');
      await tester.ensureVisible(skipBtn);
      await tester.pumpAndSettle();
      expect(skipBtn, findsOneWidget);

      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      // Verify SubmitAnswer(true) was dispatched
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('5. Drag-and-drop correct fuel cell option onto pneumatic port triggers DynamicAnagramWrapper',
        (tester) async {
      await pumpClozeTest(tester);

      // Drag WINDOW option onto pneumatic port target (DRAG HERE)
      final source = find.text('WINDOW');
      final target = find.text('DRAG HERE');

      final firstLocation = tester.getCenter(source);
      final targetLocation = tester.getCenter(target);

      final gesture = await tester.startGesture(firstLocation);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(targetLocation);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify DynamicAnagramWrapper opened
      expect(find.byType(DynamicAnagramWrapper), findsOneWidget);
    });

    testWidgets('6. Drag-and-drop incorrect fuel cell option onto pneumatic port triggers SubmitAnswer(false)',
        (tester) async {
      await pumpClozeTest(tester);

      // Drag ROAD option onto pneumatic port target (DRAG HERE)
      final source = find.text('ROAD');
      final target = find.text('DRAG HERE');

      final firstLocation = tester.getCenter(source);
      final targetLocation = tester.getCenter(target);

      final gesture = await tester.startGesture(firstLocation);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(targetLocation);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify wrong answer submission
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('7. Interaction lockout: once an option is docked, fuel cells ignore further taps',
        (tester) async {
      await pumpClozeTest(tester);

      // Tap on correct option
      await tester.tap(find.text('WINDOW'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Attempt to tap another option (ignored due to lockout)
      await tester.tap(find.text('ROAD'), warnIfMissed: false);
      await tester.pump();

      // SubmitAnswer should not be called with false
      verifyNever(() => mockReadingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('8. Hint button in app bar dispatches ReadingHintUsed',
        (tester) async {
      await pumpClozeTest(tester);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);

      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockReadingBloc.add(const ReadingHintUsed())).called(2);
    });

    testWidgets('9. Displays GameShimmerLoading when quest is null or uninitialized',
        (tester) async {
      const loadingState = ReadingInitial();
      await pumpClozeTest(tester, state: loadingState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ClozeTestPneumaticPort), findsNothing);
    });

    testWidgets('10. Level 1 displays GameBriefingLayer and dismisses on start tap',
        (tester) async {
      await pumpClozeTest(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final startButton = find.byType(ElevatedButton);
      if (startButton.evaluate().isNotEmpty) {
        await tester.tap(startButton);
        await tester.pumpAndSettle();
        expect(find.byType(GameBriefingLayer), findsNothing);
      }
    });

    testWidgets('11. Renders cleanly in dark theme mode and small screen 320dp width without overflow',
        (tester) async {
      await pumpClozeTest(
        tester,
        themeMode: ThemeMode.dark,
        width: 320,
        height: 568,
      );

      expect(find.byType(ClozeTestScreen), findsOneWidget);
      expect(find.text('WINDOW'), findsOneWidget);
      expect(find.text('ROAD'), findsOneWidget);
      expect(find.text('SHELF'), findsOneWidget);
      expect(find.text('RIVER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

